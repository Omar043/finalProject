db.users.inserOne({ username: 'DebugUser', hashedPassword: "DebugPasswordNotHashed", profileImage: "0"});
db.events.insertOne({eventId: "DebugEventId", eventName: "DebugEventName", eventFounder: "DebugUser", publicOrPrivate: "public", category: "DebugCategory", startingTime: "0", endingTime: "0", isActive: "false"});
db.chats.insertOne({chatId: "DebugChat", eventId: "DebugEventId"});