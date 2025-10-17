-- Check if job_cart has price columns and if they're NULL

SELECT 
    job_cart_id,
    job_cart_item,
    job_cart_min_price,
    job_cart_max_price,
    service_id,
    client_id
FROM public.job_cart
ORDER BY created_at DESC
LIMIT 10;

-- Check how many have NULL prices
SELECT 
    COUNT(*) as total_job_carts,
    COUNT(job_cart_min_price) as has_min_price,
    COUNT(job_cart_max_price) as has_max_price,
    COUNT(*) - COUNT(job_cart_min_price) as null_min_price,
    COUNT(*) - COUNT(job_cart_max_price) as null_max_price
FROM public.job_cart;

