import postgres from 'postgres';
const SUPABASE_URL = 'postgresql://postgres:[eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwdWR0cnB0Ynl2d3lodmlzdGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2OTk4NjgsImV4cCI6MjA3MTI3NTg2OH0.GBo-RtgbRZCmhSAZi0c5oXynMiJNeyrs0nLsk3CaV8A]@db.spudtrptbyvwyhvistdf.supabase.co:5432/postgres'

const connectionString = process.env.SUPABASE_URL;
const sql = postgres(connectionString);

export default sql;