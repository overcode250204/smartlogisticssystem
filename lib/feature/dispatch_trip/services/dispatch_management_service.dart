import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/linehaul_trip_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_model.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';

class DispatchManagementService {
  final ApiClient _apiClient = ApiClient();

  Future<List<LinehaulTripModel>> getAllLinehaulTrips() async {
    try {
      final response = await _apiClient.get('linehaul-trip');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => LinehaulTripModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all linehaul trips: $e');
      rethrow;
    }
  }

  Future<List<LocalTripModel>> getAllLocalTrips() async {
    try {
      final response = await _apiClient.get('admin/local-trips');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => LocalTripModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all local trips: $e');
      rethrow;
    }
  }

  Future<LinehaulTripModel> getLinehaulTripById(int id) async {
    try {
      final response = await _apiClient.get('linehaul-trip/$id');
      if (response.statusCode == 200) {
        return LinehaulTripModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to get linehaul trip');
    } catch (e) {
      print('Error getting linehaul trip by id: $e');
      rethrow;
    }
  }

  Future<LocalTripModel> getLocalTripById(int id) async {
    try {
      final response = await _apiClient.get('admin/local-trips/$id');
      if (response.statusCode == 200) {
        return LocalTripModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to get local trip');
    } catch (e) {
      print('Error getting local trip by id: $e');
      rethrow;
    }
  }

  Future<void> changeLocalTripDriver(int tripId, int driverId) async {
    try {
      await _apiClient.put('admin/local-trips/$tripId/change-driver/$driverId');
    } catch (e) {
      print('Error changing local trip driver: $e');
      rethrow;
    }
  }

  Future<void> changeLocalTripVehicle(int tripId, int vehicleId) async {
    try {
      await _apiClient.put('admin/local-trips/$tripId/change-vehicle/$vehicleId');
    } catch (e) {
      print('Error changing local trip vehicle: $e');
      rethrow;
    }
  }

  Future<void> updateLinehaulTrip(int tripId, Map<String, dynamic> data) async {
    try {
      await _apiClient.put('linehaul-trip/$tripId', data: data);
    } catch (e) {
      print('Error updating linehaul trip: $e');
      rethrow;
    }
  }

  Future<void> createLinehaulTrip(Map<String, dynamic> data) async {
    try {
      await _apiClient.post('linehaul-trip', data: data);
    } catch (e) {
      print('Error creating linehaul trip: $e');
      rethrow;
    }
  }

  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    try {
      final response = await _apiClient.get('orders/status/$status');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => OrderModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting orders by status: $e');
      rethrow;
    }
  }

  Future<List<PalletModel>> getAllPallets() async {
    try {
      final response = await _apiClient.get('pallet');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => PalletModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all pallets: $e');
      rethrow;
    }
  }

  Future<void> addPalletToLinehaulTrip(int tripId, int palletId) async {
    try {
      await _apiClient.post('linehaul-trip/$tripId/add-pallet', data: {'palletId': palletId});
    } catch (e) {
      print('Error adding pallet to linehaul trip: $e');
      rethrow;
    }
  }

  Future<void> addOrderToPallet(int palletId, String orderCode) async {
    try {
      await _apiClient.post('pallet/$palletId/items', data: {'orderCode': orderCode});
    } catch (e) {
      print('Error adding order to pallet: $e');
      rethrow;
    }
  }

  Future<void> createPallet(Map<String, dynamic> data) async {
    try {
      await _apiClient.post('pallet', data: data);
    } catch (e) {
      print('Error creating pallet: $e');
      rethrow;
    }
  }

  Future<void> planLocalTrips() async {
    try {
      final response = await _apiClient.post('admin/local-trips/plan');
      if (response.statusCode == 200) {
        print('Local trips planned successfully');
      }
    } catch (e) {
      print('Error planning local trips: $e');
      rethrow;
    }
  }
}
