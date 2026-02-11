# Factory CRUD Feature - Testing Guide

## Overview
This document provides guidance for testing the newly implemented Factory CRUD feature.

## Prerequisites
- Admin account credentials
- Access to Supabase dashboard for verifying database changes
- Flutter development environment set up

## Feature Locations

### Navigation
1. Login as Admin
2. From Dashboard, click on "Kelola Pabrik" menu item (factory icon, orange color)

### Database
- Table: `factories`
- Columns: `id`, `factory_name`, `address`, `no_telp`
- Related table: `percas_stock` (via foreign key `id_factory`)

## Test Cases

### 1. View Factory List
**Steps:**
1. Navigate to Factory List screen via dashboard
2. Observe the factory list

**Expected Results:**
- List displays all factories with factory icon
- Each factory shows: name, address, phone number
- Search bar is visible at the top
- Total factory count is displayed
- Empty state message appears if no factories exist

### 2. Search Factories
**Steps:**
1. Type a factory name in the search bar
2. Observe the results

**Expected Results:**
- List filters in real-time as you type
- Only matching factories are displayed
- Clear (X) button appears to reset search

### 3. Create New Factory (Admin Only)
**Steps:**
1. Click the "+ Tambah Pabrik" floating action button
2. Fill in all fields:
   - Nama Pabrik: "PT. Test Factory"
   - Alamat Pabrik: "Jl. Test No. 123"
   - Nomor Telepon: "08123456789"
3. Click "Buat Pabrik"

**Expected Results:**
- Form validates required fields
- Success message appears
- Dialog closes automatically
- New factory appears in the list
- Total count increases by 1

**Validation Tests:**
- Try submitting with empty fields → Should show validation errors
- Try submitting with invalid phone format → Should validate

### 4. Edit Existing Factory (Admin Only)
**Steps:**
1. Click the three-dot menu on any factory card
2. Select "Edit"
3. Modify the factory name
4. Click "Simpan Perubahan"

**Expected Results:**
- Form is pre-filled with existing data
- Changes are saved successfully
- Success message appears
- List updates with new data

### 5. Delete Factory (Admin Only)

#### Case A: Factory without related stock
**Steps:**
1. Click the three-dot menu on a factory with no stock records
2. Select "Hapus"
3. Confirm deletion in the dialog

**Expected Results:**
- Confirmation dialog explains the data integrity rule
- Factory is deleted successfully
- Success message appears
- Factory disappears from list
- Total count decreases by 1

#### Case B: Factory with related stock (Data Integrity Check)
**Steps:**
1. Create a perca stock entry for a factory
2. Try to delete that factory
3. Confirm deletion

**Expected Results:**
- Deletion fails with clear error message
- Error message explains the relationship constraint
- Factory remains in the list
- User is instructed to delete related stock first

### 6. Permission Testing (Non-Admin Users)
**Steps:**
1. Login as Manager or Driver
2. Navigate to Factory List

**Expected Results:**
- Can view factory list (SELECT permission)
- Can search factories
- Cannot see "Tambah Pabrik" button
- Cannot edit or delete factories
- Database RLS policies prevent write operations

### 7. Integration Testing (Add Perca Stock)
**Steps:**
1. Navigate to "Tambah Stok Perca" screen
2. Open the factory dropdown

**Expected Results:**
- Dropdown shows all factories with correct names
- Can select a factory
- Factory data is properly linked when saving stock

## Database Verification

### RLS Policies Check
Run in Supabase SQL Editor:
```sql
-- Should show 4 policies for factories table
SELECT * FROM pg_policies WHERE tablename = 'factories';

-- Test as admin (replace USER_ID with actual admin UUID)
SELECT * FROM factories; -- Should work
INSERT INTO factories (factory_name, address, no_telp) 
VALUES ('Test', 'Test Address', '08123'); -- Should work
```

### Data Integrity Check
```sql
-- This should fail due to foreign key constraint
DELETE FROM factories 
WHERE id IN (
  SELECT DISTINCT id_factory FROM percas_stock
);
```

## Known Limitations
- Image upload not implemented for factories (only name, address, phone)
- Pagination set to 50 items per page (should be sufficient for most use cases)
- Search only filters by factory name (not address or phone)

## Rollback Plan
If issues are found:
1. Remove navigation from dashboard (management_menu.dart)
2. Revert to old Factory model if needed
3. RLS policies can be dropped: `DROP POLICY IF EXISTS "policy_name" ON public.factories;`

## Support
For issues or questions, contact the development team or check:
- Repository: dwirez99/majunkita
- Branch: copilot/add-crud-for-factory-data
- PR: feat: CRUD for Factory Data
