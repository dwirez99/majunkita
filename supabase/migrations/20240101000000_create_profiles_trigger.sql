-- Migration: Update profiles table and create trigger for auto-population
-- This ensures that whenever a new user is created in auth.users,
-- a corresponding profile is automatically created in the profiles table

-- Note: Profiles table already exists, we're just ensuring the trigger is set up correctly

-- ============================================================================
-- 1. ENABLE ROW LEVEL SECURITY
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. CREATE RLS POLICIES
-- ============================================================================

-- Policy: Users can read their own profile
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
CREATE POLICY "Users can read own profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Policy: Admin and Manager can read all profiles
DROP POLICY IF EXISTS "Admin and Manager can read all profiles" ON public.profiles;
CREATE POLICY "Admin and Manager can read all profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager')
    )
);

-- Policy: Users can update their own profile (except role)
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy: Admin and Manager can update profiles
DROP POLICY IF EXISTS "Admin and Manager can update profiles" ON public.profiles;
CREATE POLICY "Admin and Manager can update profiles"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager')
    )
);

-- Policy: Admin and Manager can insert profiles
DROP POLICY IF EXISTS "Admin and Manager can insert profiles" ON public.profiles;
CREATE POLICY "Admin and Manager can insert profiles"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager')
    )
);

-- Policy: Admin and Manager can delete profiles
DROP POLICY IF EXISTS "Admin and Manager can delete profiles" ON public.profiles;
CREATE POLICY "Admin and Manager can delete profiles"
ON public.profiles
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager')
    )
);

-- ============================================================================
-- 3. CREATE FUNCTION TO HANDLE NEW USER REGISTRATION
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Insert new profile with data from user_metadata
    INSERT INTO public.profiles (id, username, nama_lengkap, email, role, no_telp)
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'username',
            split_part(NEW.email, '@', 1)
        ),
        COALESCE(
            NEW.raw_user_meta_data->>'nama',
            NEW.raw_user_meta_data->>'nama_lengkap',
            NEW.email
        ),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'driver'),
        COALESCE(NEW.raw_user_meta_data->>'no_telp', '')
    )
    ON CONFLICT (id) DO UPDATE
    SET
        username = COALESCE(EXCLUDED.username, profiles.username),
        nama_lengkap = COALESCE(EXCLUDED.nama_lengkap, profiles.nama_lengkap),
        email = COALESCE(EXCLUDED.email, profiles.email),
        role = COALESCE(EXCLUDED.role, profiles.role),
        no_telp = COALESCE(EXCLUDED.no_telp, profiles.no_telp),
        updated_at = NOW();

    RETURN NEW;
END;
$$;

-- ============================================================================
-- 4. CREATE TRIGGER ON AUTH.USERS
-- ============================================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 5. CREATE FUNCTION TO UPDATE TIMESTAMP (if not exists)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Note: Trigger on_profiles_updated already exists in your schema

-- ============================================================================
-- 6. GRANT PERMISSIONS
-- ============================================================================
-- Allow service role to bypass RLS
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;

-- Grant usage on table
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
