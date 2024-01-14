import Random "mo:base/Random";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Text "mo:base/Text";

actor PetriNet {

    private func bit(b : Bool) : Nat {
        if (b) 1 else 0;
    };

    private func randomFromEntropy(f : Random.Finite, max : Nat) : ?Nat {
        assert max > 0;
        do ? {
            if (max == 1) return null;
            var k = bit(f.coin()!);
            var n = max / 2;
            while (n > 1) {
                k := k * 2 + bit(f.coin()!);
                n := n / 2;
            };
            if (k < max) return ?k else randomFromEntropy(f, max)!;
        };
    };

    private func getRandom() : async ?Nat {
        let entropy = await Random.blob();
        var f = Random.Finite(entropy);
        var n = randomFromEntropy(f, 1000);
        return n;
    };
    type State = { #Idle; #Producing; #Consuming };
    type Token = { count : Nat; state : State };
    type Transition = shared (Token) -> async Token;
    type Node = { token : Token; transition : Transition };

    // Transition function for producer
    public func producerContract(t : Token) : async Token {
        return {
            count = t.count + 1;
            state = #Idle;
        };
    };

    // Transition function for consumer
    public func consumerContract(t : Token) : async Token {
        var token = t;
        // consume when count is multiple of 3
        if (token.count % 3 == 0) {
            token := {t with state = #Consuming};
        };
        // consume until
        while (token.state == #Consuming and token.count > 0) {
            token := {
                count = token.count - 1;
                state = await doThingsAndUpdate(token);
            };
        };
        return token;
    };

    private func doThingsAndUpdate(token : Token) : async State {
        let randomNumberOpt = await getRandom();
        switch (randomNumberOpt) {
            case (null) { return #Idle };
            case (?randomNumber) {
                if (randomNumber % token.count == 0) {
                    return #Idle;
                } else {
                    return #Consuming;
                };
            };
        };
    };

    // Transition execution function
    private func fireTransition(node : Node) : async Node {
        var mutableToken = await node.transition(node.token);
        return { node with token = mutableToken };
    };

    var producerNode : Node = {
        token = { count = 0; state = #Producing };
        transition = producerContract;
    };

    var consumerNode : Node = {
        token = { count = 0; state = #Consuming };
        transition = consumerContract;
    };

    public func producer() : async Node {
        Debug.print("1. producerNode.token=" # debug_show(producerNode.token));
        producerNode := await fireTransition(producerNode);
        Debug.print("2. producerNode.token=" # debug_show(producerNode.token));
        consumerNode := { consumerNode with token = producerNode.token };
        return producerNode;
    };

    public func consumer() : async Node {
        // Debug.print("1. consumerNode.token=" # debug_show(consumerNode.token));
        consumerNode := await fireTransition(consumerNode);
        producerNode := { producerNode with token = consumerNode.token };
        // Debug.print("2. consumerNode.token=" # debug_show(consumerNode.token));
        return consumerNode;
    };

    public func driver(n : Nat) : async Nat {
        var loopCount : Nat = 0;
        for (i in Iter.range(0, n - 1)) {
            ignore await producer();
        };
        while (consumerNode.token.count > 0) {
            ignore await consumer();
            loopCount += 1;
            if (consumerNode.token.count > 0) {
                ignore await producer();
            };
        };
        return loopCount;
    };
};
