-- Enhanced schema with payment tracking
-- Run these statements after your main schema

-- Create payment status enum
CREATE TYPE payment_status_enum AS ENUM (
  'pending',
  'processing',
  'completed',
  'failed',
  'refunded',
  'cancelled'
);

-- Create payment method enum
CREATE TYPE payment_method_enum AS ENUM (
  'credit_card',
  'debit_card',
  'bank_transfer',
  'cash',
  'mobile_payment'
);

-- Create payments table
CREATE TABLE public.payment (
  payment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL,
  amount numeric NOT NULL,
  payment_method payment_method_enum NOT NULL,
  payment_status payment_status_enum DEFAULT 'pending',
  transaction_reference text,
  payment_date timestamp without time zone,
  processed_at timestamp without time zone,
  failure_reason text,
  refund_amount numeric DEFAULT 0,
  refund_reason text,
  refund_date timestamp without time zone,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT payment_booking_fkey FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id)
);

-- Create payment history for audit trail
CREATE TABLE public.payment_history (
  payment_history_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id uuid NOT NULL,
  action text NOT NULL, -- 'created', 'processing', 'completed', 'failed', 'refunded'
  performed_at timestamp without time zone DEFAULT now(),
  details text,
  CONSTRAINT payment_history_payment_fkey FOREIGN KEY (payment_id) REFERENCES public.payment(payment_id)
);

-- Add payment-related indexes
CREATE INDEX idx_payment_booking ON public.payment (booking_id);
CREATE INDEX idx_payment_status ON public.payment (payment_status);
CREATE INDEX idx_payment_date ON public.payment (payment_date);
CREATE INDEX idx_payment_history_payment ON public.payment_history (payment_id);

-- Update booking table to reference payment
ALTER TABLE public.booking
ADD COLUMN payment_id uuid,
ADD CONSTRAINT booking_payment_fkey FOREIGN KEY (payment_id) REFERENCES public.payment(payment_id);

-- Add function to create payment when booking is created
CREATE OR REPLACE FUNCTION public.fn_create_initial_payment()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Create initial payment record when booking is created
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.payment (
      booking_id,
      amount,
      payment_method,
      payment_status,
      created_at
    ) VALUES (
      NEW.booking_id,
      NEW.booking_total_price,
      'credit_card', -- default, can be changed later
      'pending',
      now()
    );
  END IF;
  RETURN NEW;
END;
$$;

-- Create trigger for automatic payment creation
CREATE TRIGGER trg_booking_create_payment
AFTER INSERT ON public.booking
FOR EACH ROW
EXECUTE FUNCTION public.fn_create_initial_payment();


