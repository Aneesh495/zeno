package zeno.event;

import zeno.event.SimulationEvent;

/**
 * High-throughput publish-subscribe event bus for simulation events.
 */
class EventBus {
    private var listeners: Array<SimulationEvent -> Void>;

    public function new() {
        this.listeners = new Array<SimulationEvent -> Void>();
    }

    public function subscribe(listener: SimulationEvent -> Void): Void {
        if (listeners.indexOf(listener) < 0) {
            listeners.push(listener);
        }
    }

    public function unsubscribe(listener: SimulationEvent -> Void): Void {
        var idx = listeners.indexOf(listener);
        if (idx >= 0) {
            listeners.splice(idx, 1);
        }
    }

    public function dispatch(event: SimulationEvent): Void {
        var len = listeners.length;
        for (i in 0...len) {
            listeners[i](event);
        }
    }

    public function clear(): Void {
        while (listeners.length > 0) listeners.pop();
    }
}
