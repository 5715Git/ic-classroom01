// Persistent logger keeping track of what is going on.

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Deque "mo:base/Deque";
import Nat "mo:base/Nat";
import List "mo:base/List";
import Int "mo:base/Int";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Logger "mo:ic-logger/Logger";
import Box "modules/Box";

import Debug "mo:base/Debug"

actor TextLogger {
  public type ActorBox = {
      index : Nat;
      size : Nat;
      id : Text;
  };

  // let OWNER = msg.caller;
  let actor_size = 100;

  stable var actor_box_index = 0;
  stable var actorBoxList : List.List<ActorBox> = List.nil();

  // var boxs = Buffer.Buffer<ActorBox>(1);
  // Principals that are allowed to log messages.
  // stable var allowed : [Principal] = [OWNER];

  // Set allowed principals.
  // public shared (msg) func allow(ids: [Principal]) {
  //   // assert(msg.caller == OWNER);
  //   allowed := ids;
  // };

  // Add a set of messages to the log.
  public shared (msg) func append(msgs: [Text]) {
    // assert(Option.isSome(Array.find(allowed, func (id: Principal) : Bool { msg.caller == id })));
    // logger.append(msgs);
    let box = List.pop(actorBoxList);
    let canister :Box.Box = actor(box.id);
    if(canister.size+1 < actor_size){
      await canister.append(msgs);
      canister.size += 1;
    }
    else {
      let box =  createBox();
      let canister :Box.Box = actor(box.id);
      await canister.append(msgs);
      box.size += 1;
    }
    
  };


  private func createBox(): async Box.Box {
    let box = await Box.Box();
    let pid = Principal.fromActor(box);
    actorBoxList := List.push( {index=actor_box_index;size=0;id=Principal.toText(pid)},actorBoxList);
    actor_box_index += 1;
    box
  };

  // Return the messages between from and to indice (inclusive).
  public shared (msg) func view(from: Nat, to: Nat) : async Logger.View<Text> {
    // assert(msg.caller == OWNER);
    assert(from <= to);
    let end = to / actor_size;
    var start = from / actor_size;
    var _fr = from % actor_size;
    var messages: [Text] = [];
    for(box in Iter.fromList(actorBoxList)) {
      if(box.index>=from and box.index<=end) {
        let _to = if(start < end){
          actor_size;
        }else{
          to % actor_size;
        };
        let canister :Box.Box = actor(Principal.toText(box.id));
        let msgs = await canister.view(_fr, _to);
        messages := Array.append<Text>(messages,msgs.messages);
      };
    };
    return {
      start_index = from;
      messages = messages;
    };
  };
}
