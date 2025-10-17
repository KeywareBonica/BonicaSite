-- Enhanced schema with cancellation support
-- Run these ALTER statements after your main schema

-- Add cancellation tracking to job_cart
ALTER TABLE public.job_cart 
ADD COLUMN cancelled_at timestamp without time zone,
ADD COLUMN cancelled_by uuid,
ADD COLUMN cancellation_reason text;

-- Add cancellation tracking to quotation
ALTER TABLE public.quotation
ADD COLUMN cancelled_at timestamp without time zone,
ADD COLUMN cancelled_by uuid,
ADD COLUMN cancellation_reason text;

-- Add cancellation tracking to booking
ALTER TABLE public.booking
ADD COLUMN cancelled_at timestamp without time zone,
ADD COLUMN cancelled_by uuid,
ADD COLUMN cancellation_reason text,
ADD COLUMN cancellation_fee numeric DEFAULT 0;

-- Add cancellation status enum
CREATE TYPE cancellation_status_enum AS ENUM (
  'requested',
  'approved', 
  'rejected',
  'completed'
);

-- Create cancellation requests table
CREATE TABLE public.cancellation_request (
  cancellation_request_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL,
  requested_by uuid NOT NULL,
  requested_by_type user_type_enum NOT NULL,
  reason text NOT NULL,
  requested_at timestamp without time zone DEFAULT now(),
  status cancellation_status_enum DEFAULT 'requested',
  processed_by uuid,
  processed_at timestamp without time zone,
  admin_notes text,
  CONSTRAINT cancellation_request_booking_fkey FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id)
);

-- Add indexes for cancellation queries
CREATE INDEX idx_cancellation_request_booking ON public.cancellation_request (booking_id);
CREATE INDEX idx_cancellation_request_status ON public.cancellation_request (status);
CREATE INDEX idx_job_cart_cancelled ON public.job_cart (cancelled_at);
CREATE INDEX idx_quotation_cancelled ON public.quotation (cancelled_at);
CREATE INDEX idx_booking_cancelled ON public.booking (cancelled_at);







