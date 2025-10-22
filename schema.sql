-- === prerequisites ===
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- === enums for strong typing ===
CREATE TYPE job_cart_status_enum AS ENUM (
  'pending',                 -- created, waiting for providers to quote
  'quotations_in_progress',  -- quotations exist
  'awaiting_client_decision',
  'quotation_accepted',
  'completed',
  'cancelled'
);

CREATE TYPE quotation_status_enum AS ENUM (
  'pending',    -- submitted by provider, awaiting client
  'accepted',   -- chosen by client (only one per job_cart)
  'rejected',   -- explicitly rejected by client
  'withdrawn'   -- provider withdrew the quote
);

CREATE TYPE notification_type_enum AS ENUM ('info','success','warning','error');
CREATE TYPE user_type_enum AS ENUM ('client','service_provider');

-- === core tables ===
CREATE TABLE public.client (
  client_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_name text NOT NULL,
  client_surname text NOT NULL,
  client_password text NOT NULL,
  client_contact text NOT NULL,
  client_email text NOT NULL UNIQUE,
  client_city text,
  client_town text,
  client_street_name text,
  client_house_number text,
  client_postal_code text,
  client_preferred_notification text,
  created_at timestamp without time zone DEFAULT now(),
  client_province text
);

CREATE TABLE public.event (
  event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type text NOT NULL,
  event_date date NOT NULL,
  event_start_time time without time zone NOT NULL,
  event_end_time time without time zone,
  event_location text,
  created_at timestamp without time zone DEFAULT now()
);

CREATE TABLE public.service (
  service_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name text NOT NULL,
  service_type text NOT NULL,
  service_description text
);

CREATE TABLE public.service_provider (
  service_provider_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_provider_name text NOT NULL,
  service_provider_surname text NOT NULL,
  service_provider_password text NOT NULL,
  service_provider_contactno text NOT NULL,
  service_provider_email text NOT NULL UNIQUE,
  service_provider_location text,
  service_provider_operating_days text[],           -- e.g. ARRAY['Mon','Tue']
  service_provider_base_rate numeric,
  service_provider_overtime_rate numeric,
  service_provider_caption text,
  service_provider_rating numeric DEFAULT 0.00,
  service_provider_description text,
  service_provider_verification boolean DEFAULT false,
  service_id uuid,                                  -- if single-service; consider many-to-many later
  created_at timestamp without time zone DEFAULT now(),
  service_provider_operating_times jsonb,
  CONSTRAINT service_provider_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(service_id)
);

-- job_cart created first WITHOUT accepted_quotation_id to avoid circular FK
CREATE TABLE public.job_cart (
  job_cart_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid,
  job_cart_created_date date DEFAULT CURRENT_DATE,
  job_cart_created_time time without time zone DEFAULT CURRENT_TIME,
  job_cart_status job_cart_status_enum DEFAULT 'pending',
  created_at timestamp without time zone DEFAULT now(),
  service_id uuid NOT NULL,
  client_id uuid NOT NULL,
  job_cart_item text,
  job_cart_details text,
  job_cart_min_price numeric,
  job_cart_max_price numeric,
  CONSTRAINT job_cart_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(event_id),
  CONSTRAINT job_cart_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(service_id),
  CONSTRAINT job_cart_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.client(client_id)
);

-- quotation references job_cart
CREATE TABLE public.quotation (
  quotation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_provider_id uuid NOT NULL,
  job_cart_id uuid NOT NULL,
  quotation_price numeric NOT NULL,
  quotation_details text,
  quotation_file_path text,
  quotation_file_name text,
  quotation_submission_date date DEFAULT CURRENT_DATE,
  quotation_submission_time time without time zone DEFAULT CURRENT_TIME,
  quotation_status quotation_status_enum DEFAULT 'pending',
  created_at timestamp without time zone DEFAULT now(),
  event_id uuid,
  booking_id uuid,   -- nullable until a booking is created
  service_id uuid,
  CONSTRAINT quotation_service_provider_id_fkey FOREIGN KEY (service_provider_id) REFERENCES public.service_provider(service_provider_id),
  CONSTRAINT quotation_job_cart_id_fkey FOREIGN KEY (job_cart_id) REFERENCES public.job_cart(job_cart_id),
  CONSTRAINT quotation_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(event_id),
  CONSTRAINT quotation_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(service_id)
);

-- now add accepted_quotation_id FK to job_cart (no circular constraint since quotation already exists)
ALTER TABLE public.job_cart
ADD COLUMN accepted_quotation_id uuid NULL,
ADD CONSTRAINT job_cart_accepted_quotation_fkey
  FOREIGN KEY (accepted_quotation_id)
  REFERENCES public.quotation(quotation_id);

-- booking references accepted quotation (nullable until created)
CREATE TABLE public.booking (
  booking_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_date date NOT NULL,
  booking_status text DEFAULT 'pending',
  booking_special_requests text,
  client_id uuid NOT NULL,
  event_id uuid NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  booking_min_price numeric,
  booking_max_price numeric,
  booking_location text,
  payment_status text,
  booking_total_price numeric,
  quotation_id uuid,   -- link back to the accepted quotation
  CONSTRAINT booking_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.client(client_id),
  CONSTRAINT booking_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(event_id),
  CONSTRAINT booking_quotation_fkey FOREIGN KEY (quotation_id) REFERENCES public.quotation(quotation_id)
);

CREATE TABLE public.review (
  review_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL,
  rating numeric NOT NULL,
  comment text,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT review_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id)
);

CREATE TABLE public.notification (
  notification_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  user_type user_type_enum NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  type notification_type_enum NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamp without time zone DEFAULT now(),
  read_at timestamp without time zone
);

CREATE TABLE public.resource_locks (
  lock_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_type text NOT NULL,
  resource_id text NOT NULL,
  user_id uuid NOT NULL,
  user_type user_type_enum NOT NULL,
  acquired_at timestamp without time zone DEFAULT now(),
  expires_at timestamp without time zone NOT NULL,
  created_at timestamp without time zone DEFAULT now()
);

-- Optional history table for quotations (negotiation / audit trail)
CREATE TABLE public.quotation_history (
  history_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_id uuid NOT NULL,
  action text NOT NULL, -- e.g. 'submitted','updated','withdrawn','accepted'
  performed_by uuid,
  performed_by_type user_type_enum,
  performed_at timestamp without time zone DEFAULT now(),
  details text,
  CONSTRAINT quotation_history_quotation_fkey FOREIGN KEY (quotation_id) REFERENCES public.quotation(quotation_id)
);

-- === constraints & indexes to enforce business rules ===

-- only one quotation per job_cart can have status = 'accepted'
CREATE UNIQUE INDEX uq_one_accepted_per_job_cart
  ON public.quotation (job_cart_id)
  WHERE quotation_status = 'accepted';

-- indexes for fast lookup
CREATE INDEX idx_jobcart_client ON public.job_cart (client_id);
CREATE INDEX idx_jobcart_event ON public.job_cart (event_id);
CREATE INDEX idx_quotation_jobcart ON public.quotation (job_cart_id);
CREATE INDEX idx_quotation_provider ON public.quotation (service_provider_id);
CREATE INDEX idx_booking_client ON public.booking (client_id);
CREATE INDEX idx_booking_event ON public.booking (event_id);

-- === trigger: when a quotation is accepted, set job_cart.accepted_quotation_id, update job_cart status and create booking ===
-- Function
CREATE OR REPLACE FUNCTION public.fn_handle_quotation_accepted()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  existing_booking uuid;
BEGIN
  -- Only act when status changed to 'accepted'
  IF (TG_OP = 'UPDATE') AND NEW.quotation_status = 'accepted' AND OLD.quotation_status IS DISTINCT FROM 'accepted' THEN

    -- Double-check that there isn't already an accepted quotation for this job_cart (defensive; unique index also enforces)
    PERFORM 1 FROM public.quotation
    WHERE job_cart_id = NEW.job_cart_id AND quotation_status = 'accepted' AND quotation_id <> NEW.quotation_id;
    IF FOUND THEN
      RAISE EXCEPTION 'Another quotation is already accepted for job_cart %', NEW.job_cart_id;
    END IF;

    -- Update the job_cart to point to the accepted quotation and set status
    UPDATE public.job_cart
    SET accepted_quotation_id = NEW.quotation_id,
        job_cart_status = 'quotation_accepted'
    WHERE job_cart_id = NEW.job_cart_id;

    -- Create booking if not already created for this quotation
    SELECT booking_id INTO existing_booking FROM public.booking WHERE quotation_id = NEW.quotation_id LIMIT 1;
    IF existing_booking IS NULL THEN
      INSERT INTO public.booking (
        booking_date,
        booking_status,
        booking_special_requests,
        client_id,
        event_id,
        created_at,
        booking_min_price,
        booking_max_price,
        booking_location,
        payment_status,
        booking_total_price,
        quotation_id
      )
      SELECT
        e.event_date,
        'pending',
        jc.job_cart_details,
        jc.client_id,
        COALESCE(NEW.event_id, jc.event_id),
        now(),
        jc.job_cart_min_price,
        jc.job_cart_max_price,
        jc.job_cart_details, -- or a dedicated location field
        'unpaid',
        NEW.quotation_price,
        NEW.quotation_id
      FROM public.job_cart jc
      LEFT JOIN public.event e ON jc.event_id = e.event_id
      WHERE jc.job_cart_id = NEW.job_cart_id
      RETURNING booking_id INTO existing_booking;
      -- Optionally, create a notification rows here (left to application logic or add code)
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- Trigger on quotations (after update so FK changes are visible)
CREATE TRIGGER trg_quotation_after_update
AFTER UPDATE ON public.quotation
FOR EACH ROW
EXECUTE FUNCTION public.fn_handle_quotation_accepted();

-- === sample helper: when inserting a new quotation set job_cart_status if needed ===
CREATE OR REPLACE FUNCTION public.fn_on_new_quotation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- If job_cart status was 'pending', move to 'quotations_in_progress'
  UPDATE public.job_cart
  SET job_cart_status = CASE
    WHEN job_cart_status = 'pending' THEN 'quotations_in_progress'
    WHEN job_cart_status = 'quotations_in_progress' THEN job_cart_status
    ELSE job_cart_status
  END
  WHERE job_cart_id = NEW.job_cart_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_quotation_after_insert
AFTER INSERT ON public.quotation
FOR EACH ROW
EXECUTE FUNCTION public.fn_on_new_quotation();

-- === NOTE about concurrency and locks ===
-- The partial unique index prevents multiple accepted quotations at the DB level.
-- However, for real-time/low-latency systems, consider:
--  * taking a short row-level lock on the job_cart (SELECT ... FOR UPDATE) when trying to accept a quotation
--  * or using resource_locks to coordinate acceptance across distributed app servers

-- === Optional enhancement: materialized view or function to fetch job_cart with quotations summary ===
-- (left to application-specific queries)

-- End of schema









