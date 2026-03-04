// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expedition_partner_model.dart';

/// Repository untuk CRUD data mitra expedisi (expedition_partners table).
class ExpeditionPartnerRepository {
  final SupabaseClient _supabase;

  ExpeditionPartnerRepository(this._supabase);

  // ===========================================================================
  // LOGGING HELPER
  // ===========================================================================

  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toString();
    print('[$timestamp] [$level] EXPEDITION_PARTNER_REPO: $message');
  }

  // ===========================================================================
  // READ
  // ===========================================================================

  /// Ambil semua mitra expedisi, diurutkan alfabetis berdasarkan nama.
  Future<List<ExpeditionPartnerModel>> getAll() async {
    _log('Fetching all expedition partners...');
    try {
      final response = await _supabase
          .from('expedition_partners')
          .select('id, name, no_telp, address')
          .order('name', ascending: true);

      final result = (response as List)
          .map((json) => ExpeditionPartnerModel.fromJson(json))
          .toList();
      _log('Fetched ${result.length} expedition partners');
      return result;
    } catch (e) {
      _log('Error fetching expedition partners: $e', level: 'ERROR');
      throw Exception('Gagal mengambil data mitra expedisi: $e');
    }
  }

  /// Cari mitra expedisi berdasarkan nama (case-insensitive).
  Future<List<ExpeditionPartnerModel>> search(String query) async {
    _log('Searching expedition partners: "$query"');
    try {
      final response = await _supabase
          .from('expedition_partners')
          .select('id, name, no_telp, address')
          .ilike('name', '%$query%')
          .order('name', ascending: true);

      final result = (response as List)
          .map((json) => ExpeditionPartnerModel.fromJson(json))
          .toList();
      _log('Search found ${result.length} result(s) for "$query"');
      return result;
    } catch (e) {
      _log('Error searching expedition partners: $e', level: 'ERROR');
      throw Exception('Gagal mencari mitra expedisi: $e');
    }
  }

  // ===========================================================================
  // CREATE
  // ===========================================================================

  Future<ExpeditionPartnerModel> create({
    required String name,
    String? noTelp,
    String? address,
  }) async {
    _log('Creating expedition partner: $name');
    try {
      final body = <String, dynamic>{'name': name};
      if (noTelp != null && noTelp.isNotEmpty) body['no_telp'] = noTelp;
      if (address != null && address.isNotEmpty) body['address'] = address;

      final response = await _supabase
          .from('expedition_partners')
          .insert(body)
          .select('id, name, no_telp, address')
          .single();

      final partner = ExpeditionPartnerModel.fromJson(response);
      _log('Created expedition partner: ${partner.id}');
      return partner;
    } catch (e) {
      _log('Error creating expedition partner: $e', level: 'ERROR');
      throw Exception('Gagal membuat mitra expedisi: $e');
    }
  }

  // ===========================================================================
  // UPDATE
  // ===========================================================================

  Future<ExpeditionPartnerModel> update({
    required String id,
    required String name,
    String? noTelp,
    String? address,
  }) async {
    _log('Updating expedition partner: id=$id');
    try {
      final body = <String, dynamic>{'name': name};
      // Explicitly allow clearing optional fields by setting to null
      body['no_telp'] = noTelp?.isNotEmpty == true ? noTelp : null;
      body['address'] = address?.isNotEmpty == true ? address : null;

      final response = await _supabase
          .from('expedition_partners')
          .update(body)
          .eq('id', id)
          .select('id, name, no_telp, address')
          .single();

      final partner = ExpeditionPartnerModel.fromJson(response);
      _log('Updated expedition partner: id=$id');
      return partner;
    } catch (e) {
      _log('Error updating expedition partner $id: $e', level: 'ERROR');
      throw Exception('Gagal mengupdate mitra expedisi: $e');
    }
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  Future<void> delete(String id) async {
    _log('Deleting expedition partner: id=$id');
    try {
      await _supabase
          .from('expedition_partners')
          .delete()
          .eq('id', id);
      _log('Deleted expedition partner: id=$id');
    } catch (e) {
      _log('Error deleting expedition partner $id: $e', level: 'ERROR');
      throw Exception('Gagal menghapus mitra expedisi: $e');
    }
  }
}
