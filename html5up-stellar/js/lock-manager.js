// Shared Lock Manager for Bonica Event Management System
class LockManager {
    constructor() {
        this.locks = new Map(); // resourceId -> lockInfo
        this.lockQueue = new Map(); // resourceId -> queue of waiting requests
        this.heartbeatInterval = null;
        this.lockTimeout = 300000; // 5 minutes
        this.heartbeatInterval = 30000; // 30 seconds
        this.maxLockDuration = 900000; // 15 minutes
        this.supabase = null;
        this.userId = null;
        this.userType = null;
    }

    // Initialize lock manager
    async initialize(supabaseClient) {
        this.supabase = supabaseClient;
        this.userId = localStorage.getItem('clientId') || localStorage.getItem('serviceProviderId');
        this.userType = localStorage.getItem('userType') || 'client';
        
        if (!this.userId) {
            console.warn('⚠️ Lock manager initialized without user ID');
            return;
        }

        // Start heartbeat to maintain locks
        this.startHeartbeat();
        
        // Cleanup expired locks on startup
        await this.cleanupExpiredLocks();
        
        console.log('🔒 Lock manager initialized for user:', this.userId);
    }

    // Start heartbeat to maintain active locks
    startHeartbeat() {
        this.heartbeatInterval = setInterval(async () => {
            await this.maintainLocks();
        }, this.heartbeatInterval);
    }

    // Stop heartbeat
    stopHeartbeat() {
        if (this.heartbeatInterval) {
            clearInterval(this.heartbeatInterval);
            this.heartbeatInterval = null;
        }
    }

    // Maintain active locks
    async maintainLocks() {
        try {
            const activeLocks = Array.from(this.locks.entries())
                .filter(([_, lock]) => lock.userId === this.userId);

            for (const [resourceId, lock] of activeLocks) {
                await this.updateLockHeartbeat(resourceId, lock);
            }
        } catch (error) {
            console.error('❌ Error maintaining locks:', error);
        }
    }

    // Update lock heartbeat in database
    async updateLockHeartbeat(resourceId, lock) {
        try {
            const { error } = await this.supabase
                .from('resource_locks')
                .update({
                    last_heartbeat: new Date().toISOString(),
                    expires_at: new Date(Date.now() + this.lockTimeout).toISOString()
                })
                .eq('resource_id', resourceId)
                .eq('user_id', this.userId);

            if (error) throw error;
        } catch (error) {
            console.error('❌ Error updating lock heartbeat:', error);
            // Remove lock if update fails
            this.releaseLock(resourceId);
        }
    }

    // Acquire lock for a resource
    async acquireLock(resourceType, resourceId, operation = 'edit') {
        const lockKey = `${resourceType}:${resourceId}`;
        
        try {
            // Check if resource is already locked
            const existingLock = await this.getLockInfo(lockKey);
            
            if (existingLock) {
                // Check if lock is expired
                if (new Date(existingLock.expires_at) < new Date()) {
                    await this.releaseLock(lockKey);
                } else {
                    // Resource is locked by someone else
                    return {
                        success: false,
                        locked: true,
                        lockedBy: existingLock.user_name,
                        lockedAt: existingLock.created_at,
                        expiresAt: existingLock.expires_at,
                        message: `Resource is currently being edited by ${existingLock.user_name}`
                    };
                }
            }

            // Try to acquire lock
            const lockInfo = {
                resource_id: lockKey,
                resource_type: resourceType,
                resource_record_id: resourceId,
                user_id: this.userId,
                user_type: this.userType,
                operation: operation,
                created_at: new Date().toISOString(),
                last_heartbeat: new Date().toISOString(),
                expires_at: new Date(Date.now() + this.lockTimeout).toISOString()
            };

            const { data, error } = await this.supabase
                .from('resource_locks')
                .insert([lockInfo])
                .select()
                .single();

            if (error) {
                // Lock might have been acquired by another user
                const currentLock = await this.getLockInfo(lockKey);
                if (currentLock) {
                    return {
                        success: false,
                        locked: true,
                        lockedBy: currentLock.user_name,
                        lockedAt: currentLock.created_at,
                        expiresAt: currentLock.expires_at,
                        message: `Resource is currently being edited by ${currentLock.user_name}`
                    };
                }
                throw error;
            }

            // Store lock locally
            this.locks.set(lockKey, {
                ...lockInfo,
                id: data.id,
                acquiredAt: Date.now()
            });

            console.log(`🔒 Lock acquired for ${lockKey} by ${this.userId}`);
            
            return {
                success: true,
                locked: false,
                lockId: data.id,
                message: 'Lock acquired successfully'
            };

        } catch (error) {
            console.error('❌ Error acquiring lock:', error);
            return {
                success: false,
                locked: false,
                error: error.message,
                message: 'Failed to acquire lock'
            };
        }
    }

    // Release lock
    async releaseLock(resourceId) {
        const lockKey = resourceId.includes(':') ? resourceId : `unknown:${resourceId}`;
        
        try {
            // Remove from database
            const { error } = await this.supabase
                .from('resource_locks')
                .delete()
                .eq('resource_id', lockKey)
                .eq('user_id', this.userId);

            if (error) throw error;

            // Remove from local storage
            this.locks.delete(lockKey);

            console.log(`🔓 Lock released for ${lockKey}`);
            
            return { success: true };

        } catch (error) {
            console.error('❌ Error releasing lock:', error);
            return { success: false, error: error.message };
        }
    }

    // Get lock information
    async getLockInfo(resourceId) {
        try {
            const { data, error } = await this.supabase
                .from('resource_locks')
                .select(`
                    *,
                    user:user_id (
                        client_name,
                        client_surname,
                        service_provider_name,
                        service_provider_surname
                    )
                `)
                .eq('resource_id', resourceId)
                .single();

            if (error && error.code !== 'PGRST116') throw error;

            if (data) {
                const user = data.user;
                const userName = user?.client_name ? 
                    `${user.client_name} ${user.client_surname}` :
                    `${user?.service_provider_name} ${user?.service_provider_surname}`;
                
                return {
                    ...data,
                    user_name: userName || 'Unknown User'
                };
            }

            return null;
        } catch (error) {
            console.error('❌ Error getting lock info:', error);
            return null;
        }
    }

    // Check if resource is locked
    async isLocked(resourceId) {
        const lockInfo = await this.getLockInfo(resourceId);
        
        if (!lockInfo) return { locked: false };

        // Check if lock is expired
        if (new Date(lockInfo.expires_at) < new Date()) {
            await this.releaseLock(resourceId);
            return { locked: false };
        }

        return {
            locked: true,
            lockedBy: lockInfo.user_name,
            lockedAt: lockInfo.created_at,
            expiresAt: lockInfo.expires_at,
            operation: lockInfo.operation
        };
    }

    // Wait for lock to be released
    async waitForLock(resourceId, maxWaitTime = 60000) {
        const startTime = Date.now();
        
        while (Date.now() - startTime < maxWaitTime) {
            const lockStatus = await this.isLocked(resourceId);
            
            if (!lockStatus.locked) {
                return { success: true, message: 'Lock released' };
            }

            // Wait 2 seconds before checking again
            await new Promise(resolve => setTimeout(resolve, 2000));
        }

        return {
            success: false,
            message: 'Timeout waiting for lock to be released',
            lockedBy: lockStatus.lockedBy
        };
    }

    // Force release lock (admin only)
    async forceReleaseLock(resourceId, reason = 'Admin override') {
        try {
            const { error } = await this.supabase
                .from('resource_locks')
                .delete()
                .eq('resource_id', resourceId);

            if (error) throw error;

            console.log(`🔓 Lock force-released for ${resourceId}: ${reason}`);
            
            return { success: true };

        } catch (error) {
            console.error('❌ Error force-releasing lock:', error);
            return { success: false, error: error.message };
        }
    }

    // Cleanup expired locks
    async cleanupExpiredLocks() {
        try {
            const { error } = await this.supabase
                .from('resource_locks')
                .delete()
                .lt('expires_at', new Date().toISOString());

            if (error) throw error;

            console.log('🧹 Expired locks cleaned up');

        } catch (error) {
            console.error('❌ Error cleaning up expired locks:', error);
        }
    }

    // Release all locks for current user
    async releaseAllLocks() {
        try {
            const { error } = await this.supabase
                .from('resource_locks')
                .delete()
                .eq('user_id', this.userId);

            if (error) throw error;

            this.locks.clear();
            console.log('🔓 All locks released for user:', this.userId);

        } catch (error) {
            console.error('❌ Error releasing all locks:', error);
        }
    }

    // Get locks for current user
    getCurrentUserLocks() {
        return Array.from(this.locks.entries()).map(([resourceId, lock]) => ({
            resourceId,
            resourceType: lock.resource_type,
            operation: lock.operation,
            acquiredAt: lock.acquiredAt,
            expiresAt: lock.expires_at
        }));
    }

    // Get all active locks (for monitoring)
    async getAllActiveLocks() {
        try {
            const { data, error } = await this.supabase
                .from('resource_locks')
                .select(`
                    *,
                    user:user_id (
                        client_name,
                        client_surname,
                        service_provider_name,
                        service_provider_surname
                    )
                `)
                .gt('expires_at', new Date().toISOString())
                .order('created_at', { ascending: false });

            if (error) throw error;

            return data.map(lock => {
                const user = lock.user;
                const userName = user?.client_name ? 
                    `${user.client_name} ${user.client_surname}` :
                    `${user?.service_provider_name} ${user?.service_provider_surname}`;
                
                return {
                    ...lock,
                    user_name: userName || 'Unknown User'
                };
            });

        } catch (error) {
            console.error('❌ Error getting active locks:', error);
            return [];
        }
    }

    // Lock with UI feedback
    async acquireLockWithUI(resourceType, resourceId, operation = 'edit') {
        const lockResult = await this.acquireLock(resourceType, resourceId, operation);
        
        if (lockResult.success) {
            this.showLockAcquired(resourceId);
        } else if (lockResult.locked) {
            this.showLockBlocked(resourceResult);
        } else {
            this.showLockError(lockResult);
        }
        
        return lockResult;
    }

    // Show lock acquired notification
    showLockAcquired(resourceId) {
        this.showNotification('success', 'Lock Acquired', `You now have exclusive access to ${resourceId}`);
    }

    // Show lock blocked notification
    showLockBlocked(lockResult) {
        this.showNotification('warning', 'Resource Locked', 
            `${lockResult.message}. Please try again later.`);
    }

    // Show lock error notification
    showLockError(lockResult) {
        this.showNotification('error', 'Lock Error', lockResult.message);
    }

    // Show notification
    showNotification(type, title, message) {
        // Use existing notification system or create simple alert
        if (window.RealtimeNotifications) {
            window.RealtimeNotifications.addNotification({
                id: Date.now().toString(),
                notification_type: 'system_update',
                message: `${title}: ${message}`,
                read: false,
                created_at: new Date().toISOString()
            });
        } else {
            // Fallback to browser alert
            alert(`${title}: ${message}`);
        }
    }

    // Cleanup on page unload
    cleanup() {
        this.releaseAllLocks();
        this.stopHeartbeat();
    }
}

// Create global instance
window.LockManager = new LockManager();

// Auto-cleanup on page unload
window.addEventListener('beforeunload', () => {
    if (window.LockManager) {
        window.LockManager.cleanup();
    }
});

// Lock types
window.LockTypes = {
    QUOTATION: 'quotation',
    BOOKING: 'booking',
    JOB_CART: 'job_cart',
    PAYMENT: 'payment',
    EVENT: 'event',
    CLIENT: 'client',
    SERVICE_PROVIDER: 'service_provider'
};

// Lock operations
window.LockOperations = {
    EDIT: 'edit',
    DELETE: 'delete',
    APPROVE: 'approve',
    REJECT: 'reject',
    CANCEL: 'cancel'
};
