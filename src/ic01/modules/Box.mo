import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Deque "mo:base/Deque";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";

import Logger "mo:ic-logger/Logger";

shared(msg) actor class Box() = this {

    stable var state : Logger.State<Text> = Logger.new<Text>(0, null);
    let logger = Logger.Logger<Text>(state);

    // Add a set of messages to the log.
    public shared (msg) func append(msgs: [Text]) {
        logger.append(msgs);
    };

    // Return log stats, where:
    //   start_index is the first index of log message.
    //   bucket_sizes is the size of all buckets, from oldest to newest.
    public query func stats() : async Logger.Stats {
        logger.stats()
    };

    public query func size() :async Nat {
        logger.stats().bucket_sizes[logger.stats().start_index];
    };

    // Return the messages between from and to indice (inclusive).
    public shared query (msg) func view(from: Nat, to: Nat) : async Logger.View<Text> {
        // assert(msg.caller == OWNER);
        logger.view(from, to)
    };

    // Drop past buckets (oldest first).
    public shared (msg) func pop_buckets(num: Nat) {
        logger.pop_buckets(num)
    };
}
