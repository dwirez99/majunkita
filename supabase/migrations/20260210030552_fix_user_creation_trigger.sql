-- Fix user creation trigger issues
-- 1. Fix the handle_new_user function to use correct column name
-- 2. Add missing trigger on auth.users table

-- Drop and recreate the handle_new_user function with the correct column name
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    -- Insert new profile with data from user_metadata
    INSERT INTO public.profiles (id, username, name, email, role, no_telp, address)
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'username',
            split_part(NEW.email, '@', 1)
        ),
        COALESCE(
            NEW.raw_user_meta_data->>'name',
            NEW.email
        ),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'driver'), -- Default to penjahit if no role specified
        COALESCE(NEW.raw_user_meta_data->>'no_telp', ''),
        COALESCE(NEW.raw_user_meta_data->>'address', '')
    )
    ON CONFLICT (id) DO UPDATE
    SET
        username = COALESCE(EXCLUDED.username, profiles.username),
        name = COALESCE(EXCLUDED.name, profiles.name), -- Fixed: was nama_lengkap
        email = COALESCE(EXCLUDED.email, profiles.email),
        role = COALESCE(EXCLUDED.role, profiles.role),
        no_telp = COALESCE(EXCLUDED.no_telp, profiles.no_telp),
        address = COALESCE(EXCLUDED.address, profiles.address),
        updated_at = NOW();

    RETURN NEW;
END;
$$;

-- Grant necessary permissions
GRANT ALL ON FUNCTION public.handle_new_user() TO anon;
GRANT ALL ON FUNCTION public.handle_new_user() TO authenticated;
GRANT ALL ON FUNCTION public.handle_new_user() TO service_role;

-- Create the trigger on auth.users table (if not exists)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
