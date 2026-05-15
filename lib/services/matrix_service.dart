import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/event.dart';

// Database Engines
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class MatrixService {
  static final MatrixService instance = MatrixService._internal();
  factory MatrixService() => instance;
  MatrixService._internal();

  static const String resistanceSpaceId = "!snUnIBgkbcAdunBeQa:resistance.chat";
  static const String protestEventType = "chat.resistance.protest_event";

  Client? client;

  Future<void> init() async {
    if (client != null) return;

    DatabaseFactory dbFactory;
    if (kIsWeb) {
      dbFactory = databaseFactoryFfiWeb;
    } else {
      sqfliteFfiInit();
      dbFactory = databaseFactoryFfi;
    }

    final rawDatabase = await dbFactory.openDatabase('resistance_matrix.db');
    final matrixDatabase = await MatrixSdkDatabase.init(
      'resistance_client',
      database: rawDatabase,
    );

    client = Client(
      'Resistance App',
      database: matrixDatabase,
      supportedLoginTypes: {AuthenticationTypes.password, 'm.login.dummy'},
    );

    // Ensure our custom state events are always loaded
    client!.importantStateEvents.add(protestEventType);

    await client!.init();
  }

  Future<void> login(String username, String password) async {
    if (client == null) await init();
    await client!.checkHomeserver(Uri.parse("https://matrix.resistance.chat"));

    if (client!.isLogged()) {
      await client!.logout();
    }

    await client!.login(
      LoginType.mLoginPassword,
      password: password,
      identifier: AuthenticationUserIdentifier(user: username),
    );
  }

  /// Registers and logs in a temporary guest account for anonymous access.
  Future<void> loginAsGuest() async {
    if (client == null) await init();
    
    // Only proceed if not already logged in
    if (client!.isLogged()) return;

    try {
      print("Attempting Guest Login...");
      await client!.checkHomeserver(Uri.parse("https://matrix.resistance.chat"));
      
      // 1. Try to register a guest account
      try {
        await client!.register(kind: AccountKind.guest);
      } catch (e) {
        print("Standard guest registration failed, trying shared system account...");
        // 2. Fallback: Login to a dedicated shared read-only account
        // You should create this account once on your server: @guest:resistance.chat
        await client!.login(
          LoginType.mLoginPassword,
          password: "guest_password_123", // Replace with a secure but shared password
          identifier: AuthenticationUserIdentifier(user: "guest"),
        );
      }

      print("Logged in for anonymous access: " + client!.userID.toString());
      await Future.delayed(const Duration(seconds: 2));
      await client!.sync();
    } catch (e) {
      print("Anonymous access failed completely: " + e.toString());
    }
  }

  /// Returns a stream of all protest events specifically from the registry space.
  Stream<List<ProtestEvent>> getProtestEvents() {
    if (client == null) return Stream.value([]);

    final controller = StreamController<List<ProtestEvent>>();
    
    Future<void> fetchEvents() async {
      try {
        final List<ProtestEvent> events = [];
        // Fetch ALL state events for the resistance registry space
        final stateEvents = await client!.getRoomState(resistanceSpaceId);
        
        for (final event in stateEvents) {
          if (event.type == protestEventType && event.content.isNotEmpty) {
            final id = event.stateKey?.isNotEmpty == true ? event.stateKey! : (event.eventId ?? 'unknown');
            events.add(ProtestEvent.fromMap(id, event.content));
          }
        }
        
        if (!controller.isClosed) {
          controller.add(events);
        }
      } catch (e) {
        print("Failed to fetch state events from registry space: " + e.toString());
        // We don't fallback to calculation here because the requirement is to use the space for the map.
        if (!controller.isClosed) {
          controller.add([]);
        }
      }
    }

    // 1. Initial fetch
    fetchEvents();

    // 2. Listen for future syncs to re-fetch
    final subscription = client!.onSync.stream.listen((_) {
      fetchEvents();
    });

    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> _ensureJoined(String roomId) async {
    if (client == null) throw Exception("DIAGNOSTIC: Matrix client is NULL.");
    
    print("DIAGNOSTIC: Checking membership for $roomId");
    try {
      final room = client!.getRoomById(roomId);
      final membership = room?.membership;
      print("DIAGNOSTIC: Current local membership for $roomId is: $membership");
      
      if (room == null || membership != Membership.join) {
        print("DIAGNOSTIC: Attempting joinRoomById($roomId)...");
        try {
          await client!.joinRoomById(roomId);
          print("DIAGNOSTIC: joinRoomById call finished successfully.");
        } catch (joinErr) {
          print("DIAGNOSTIC: joinRoomById FAILED: $joinErr");
          throw Exception("JOIN_FAILED: Could not join $roomId. Error: $joinErr");
        }
        
        await Future.delayed(const Duration(milliseconds: 1000));
        final postJoinRoom = client!.getRoomById(roomId);
        print("DIAGNOSTIC: Post-join local membership: ${postJoinRoom?.membership}");
      }
    } catch (e) {
      print("DIAGNOSTIC: _ensureJoined top-level error: $e");
      rethrow;
    }
  }

  Future<void> saveProtestEvent(ProtestEvent event, {String? targetRoomId}) async {
    if (client == null) throw Exception("DIAGNOSTIC: Matrix client is NULL in saveProtestEvent.");

    print("DIAGNOSTIC: Starting saveProtestEvent...");

    // 1. Ensure membership in the Registry Space
    try {
      await _ensureJoined(resistanceSpaceId);
    } catch (e) {
      throw Exception("STEP_1_FAILED (Join Space): $e");
    }

    String actionChatRoomId = targetRoomId ?? event.roomId ?? '';
    final isNewEvent = event.id.isEmpty || event.id.startsWith('stripped_');

    final currentUserId = client?.userID ?? 'UNKNOWN';
    final isLoggedIn = client?.isLogged() ?? false;
    print("DIAGNOSTIC: saveProtestEvent - User: $currentUserId, LoggedIn: $isLoggedIn");

    // Consolidate room creation logic: If we don't have a roomId, create one now.
    if (actionChatRoomId.isEmpty) {
      print("DIAGNOSTIC: Step 2 - Creating new room (needed for ${isNewEvent ? 'new' : 'update'})...");
      try {
        final serverHost = client!.homeserver?.host ?? 'matrix.resistance.chat';
        actionChatRoomId = await client!.createRoom(
          name: event.title,
          topic: event.description,
          preset: CreateRoomPreset.publicChat,
          initialState: [
            StateEvent(
              type: 'm.space.parent',
              stateKey: resistanceSpaceId,
              content: {
                'via': [serverHost],
                'canonical': true
              },
            ),
          ],
        );
        print("DIAGNOSTIC: Created room $actionChatRoomId");

        // Link the new room as a child of the registry space
        try {
          print("DIAGNOSTIC: Step 2b - Linking to space...");
          await client!.setRoomStateWithKey(
            resistanceSpaceId,
            'm.space.child',
            actionChatRoomId,
            {
              'via': [serverHost]
            },
          );
          print("DIAGNOSTIC: Linked to space successfully.");
        } catch (linkErr) {
          print("DIAGNOSTIC: Linking FAILED (Non-critical): $linkErr");
        }
      } catch (createErr) {
        String detailedError = createErr.toString();
        if (createErr is MatrixException) {
          detailedError = "[" + createErr.error.toString() + "] " + createErr.errorMessage.toString();
        }
        print("DIAGNOSTIC: createRoom FAILED: " + detailedError);
        throw Exception("STEP_2_FAILED (Create Room): " + detailedError);
      }
    }

    final content = {
      'title': event.title,
      'description': event.description,
      'locationName': event.locationName,
      'timestamp': event.timestamp.millisecondsSinceEpoch,
      'latitude': event.latitude.toString(),
      'longitude': event.longitude.toString(),
      if (event.series != null) 'series': event.series,
      'roomId': actionChatRoomId,
    };

    final String stateKey = isNewEvent
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : event.id;

    // 3. PUBLISH REGISTRY ENTRY
    print("DIAGNOSTIC: Step 3 - Publishing registry entry...");
    try {
      await client!.setRoomStateWithKey(
        resistanceSpaceId,
        protestEventType,
        stateKey,
        content,
      );
      print("DIAGNOSTIC: Successfully published registry entry.");
    } catch (publishErr) {
      print("DIAGNOSTIC: Step 3 FAILED: $publishErr");
      throw Exception("STEP_3_FAILED (Publish Metadata): $publishErr");
    }
  }

  /// Deletes a protest event by clearing its registry entry in the space.
  Future<void> deleteProtestEvent(String eventId) async {
    if (client == null) return;

    await _ensureJoined(resistanceSpaceId);

    await client!.setRoomStateWithKey(
      resistanceSpaceId,
      protestEventType,
      eventId,
      {},
    );
  }
}
