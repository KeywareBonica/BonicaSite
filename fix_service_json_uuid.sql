-- Fix service.json by replacing invalid UUID characters with valid ones
-- This script shows the corrected service IDs that should be used

-- The issue: service.json contains invalid UUID characters (g-z)
-- Valid UUID characters are only: 0-9, a-f, and hyphens

-- Here are the corrected service IDs for service.json:

SELECT 
    'CORRECTED SERVICE IDs FOR SERVICE.JSON' as status,
    'Replace the invalid UUIDs in service.json with these corrected ones:' as instruction;

-- Service ID mappings (invalid -> corrected):
-- Original: b2c3d4e5-f6g7-8901-bcde-f23456789012 -> Corrected: b2c3d4e5-f6a7-8901-bcde-f23456789012
-- Original: c3d4e5f6-g7h8-9012-cdef-345678901234 -> Corrected: c3d4e5f6-a7b8-9012-cdef-345678901234  
-- Original: d4e5f6g7-h8i9-0123-def0-456789012345 -> Corrected: d4e5f6a7-b8c9-0123-def0-456789012345
-- Original: e5f6g7h8-i9j0-1234-ef01-567890123456 -> Corrected: e5f6a7b8-c9d0-1234-ef01-567890123456
-- Original: f6g7h8i9-j0k1-2345-f012-678901234567 -> Corrected: f6a7b8c9-d0e1-2345-f012-678901234567
-- Original: g7h8i9j0-k1l2-3456-0123-789012345678 -> Corrected: a7b8c9d0-e1f2-3456-0123-789012345678
-- Original: h8i9j0k1-l2m3-4567-1234-890123456789 -> Corrected: b8c9d0e1-f2a3-4567-1234-890123456789
-- Original: i9j0k1l2-m3n4-5678-2345-901234567890 -> Corrected: c9d0e1f2-a3b4-5678-2345-901234567890
-- Original: j0k1l2m3-n4o5-6789-3456-012345678901 -> Corrected: d0e1f2a3-b4c5-6789-3456-012345678901
-- Original: k1l2m3n4-o5p6-7890-4567-123456789012 -> Corrected: e1f2a3b4-c5d6-7890-4567-123456789012
-- Original: l2m3n4o5-p6q7-8901-5678-234567890123 -> Corrected: f2a3b4c5-d6e7-8901-5678-234567890123
-- Original: m3n4o5p6-q7r8-9012-6789-345678901234 -> Corrected: a3b4c5d6-e7f8-9012-6789-345678901234
-- Original: n4o5p6q7-r8s9-0123-7890-456789012345 -> Corrected: b4c5d6e7-f8a9-0123-7890-456789012345
-- Original: o5p6q7r8-s9t0-1234-8901-567890123456 -> Corrected: c5d6e7f8-a9b0-1234-8901-567890123456
-- Original: p6q7r8s9-t0u1-2345-9012-678901234567 -> Corrected: d6e7f8a9-b0c1-2345-9012-678901234567
-- Original: q7r8s9t0-u1v2-3456-0123-789012345678 -> Corrected: e7f8a9b0-c1d2-3456-0123-789012345678
-- Original: r8s9t0u1-v2w3-4567-1234-890123456789 -> Corrected: f8a9b0c1-d2e3-4567-1234-890123456789
-- Original: s9t0u1v2-w3x4-5678-2345-901234567890 -> Corrected: a9b0c1d2-e3f4-5678-2345-901234567890
-- Original: t0u1v2w3-x4y5-6789-3456-012345678901 -> Corrected: b0c1d2e3-f4a5-6789-3456-012345678901
-- Original: u1v2w3x4-y5z6-7890-4567-123456789012 -> Corrected: c1d2e3f4-a5b6-7890-4567-123456789012
-- Original: v2w3x4y5-z6a7-8901-5678-234567890123 -> Corrected: d2e3f4a5-b6c7-8901-5678-234567890123
-- Original: w3x4y5z6-a7b8-9012-6789-345678901234 -> Corrected: e3f4a5b6-c7d8-9012-6789-345678901234

-- Valid service IDs that should be used in service.json:
SELECT 
    '468e17ac-89a7-4f64-b0dd-c3006c93c018' as service_id, 'Hair Styling & Makeup' as service_name
UNION ALL SELECT 'd9b03999-ab17-4288-8fae-292d3f95386a', 'Makeup & Hair'
UNION ALL SELECT '81c4b860-1c88-4503-bbe8-a03ab14e771c', 'Photography'
UNION ALL SELECT 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Makeup Artist'
UNION ALL SELECT 'b2c3d4e5-f6a7-8901-bcde-f23456789012', 'Videography'
UNION ALL SELECT 'c3d4e5f6-a7b8-9012-cdef-345678901234', 'DJ Services'
UNION ALL SELECT 'd4e5f6a7-b8c9-0123-def0-456789012345', 'Catering'
UNION ALL SELECT 'e5f6a7b8-c9d0-1234-ef01-567890123456', 'Decoration'
UNION ALL SELECT 'f6a7b8c9-d0e1-2345-f012-678901234567', 'Venue'
UNION ALL SELECT 'a7b8c9d0-e1f2-3456-0123-789012345678', 'Florist'
UNION ALL SELECT 'b8c9d0e1-f2a3-4567-1234-890123456789', 'MC'
UNION ALL SELECT 'c9d0e1f2-a3b4-5678-2345-901234567890', 'Security'
UNION ALL SELECT 'd0e1f2a3-b4c5-6789-3456-012345678901', 'Sound System'
UNION ALL SELECT 'e1f2a3b4-c5d6-7890-4567-123456789012', 'Stage Design'
UNION ALL SELECT 'f2a3b4c5-d6e7-8901-5678-234567890123', 'Photo Booth'
UNION ALL SELECT 'a3b4c5d6-e7f8-9012-6789-345678901234', 'Hair Styling'
UNION ALL SELECT 'b4c5d6e7-f8a9-0123-7890-456789012345', 'Event Planning'
UNION ALL SELECT 'c5d6e7f8-a9b0-1234-8901-567890123456', 'Lighting'
UNION ALL SELECT 'd6e7f8a9-b0c1-2345-9012-678901234567', 'Musician'
UNION ALL SELECT 'e7f8a9b0-c1d2-3456-0123-789012345678', 'Caterer'
UNION ALL SELECT 'f8a9b0c1-d2e3-4567-1234-890123456789', 'DJ'
UNION ALL SELECT 'a9b0c1d2-e3f4-5678-2345-901234567890', 'Decorator'
UNION ALL SELECT 'b0c1d2e3-f4a5-6789-3456-012345678901', 'Flowers'
UNION ALL SELECT 'c1d2e3f4-a5b6-7890-4567-123456789012', 'Music'
UNION ALL SELECT 'd2e3f4a5-b6c7-8901-5678-234567890123', 'Photographer'
UNION ALL SELECT 'e3f4a5b6-c7d8-9012-6789-345678901234', 'Hair Stylist';
