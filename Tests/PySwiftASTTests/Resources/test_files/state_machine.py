"""
State machine implementation with enums, pattern matching, and protocols.
"""
from enum import Enum, auto
from typing import Protocol, Optional, List, Dict, Callable, Any
from dataclasses import dataclass

class EventType(Enum):
    CONNECT = auto()
    DISCONNECT = auto()
    SEND_MESSAGE = auto()
    RECEIVE_MESSAGE = auto()
    ERROR = auto()
    TIMEOUT = auto()

class State(Enum):
    DISCONNECTED = auto()
    CONNECTING = auto()
    CONNECTED = auto()
    RECONNECTING = auto()
    ERROR = auto()
    CLOSED = auto()

@dataclass
class Event:
    type: EventType
    data: Optional[Any] = None
    timestamp: float = 0.0

class StateHandler(Protocol):
    def handle(self, event: Event) -> Optional[State]:
        ...

@dataclass
class Transition:
    from_state: State
    event_type: EventType
    to_state: State
    action: Optional[Callable[[Event], None]] = None

class StateMachine:
    def __init__(self, initial_state: State):
        self.current_state = initial_state
        self.transitions: List[Transition] = []
        self.state_handlers: Dict[State, Callable[[Event], Optional[State]]] = {}
        self.history: List[tuple[State, Event]] = []
    
    def add_transition(
        self, 
        from_state: State, 
        event_type: EventType, 
        to_state: State,
        action: Optional[Callable[[Event], None]] = None
    ):
        transition = Transition(from_state, event_type, to_state, action)
        self.transitions.append(transition)
    
    def on_state(self, state: State, handler: Callable[[Event], Optional[State]]):
        self.state_handlers[state] = handler
    
    def process_event(self, event: Event) -> bool:
        self.history.append((self.current_state, event))
        
        match (self.current_state, event.type):
            case (State.DISCONNECTED, EventType.CONNECT):
                return self._transition_to(State.CONNECTING, event)
            
            case (State.CONNECTING, EventType.RECEIVE_MESSAGE) if event.data == 'connected':
                return self._transition_to(State.CONNECTED, event)
            
            case (State.CONNECTING, EventType.TIMEOUT):
                return self._transition_to(State.RECONNECTING, event)
            
            case (State.CONNECTED, EventType.SEND_MESSAGE):
                print(f"Sending: {event.data}")
                return True
            
            case (State.CONNECTED, EventType.DISCONNECT):
                return self._transition_to(State.DISCONNECTED, event)
            
            case (State.RECONNECTING, EventType.CONNECT):
                return self._transition_to(State.CONNECTING, event)
            
            case (_, EventType.ERROR):
                return self._transition_to(State.ERROR, event)
            
            case _:
                print(f"Unhandled event {event.type} in state {self.current_state}")
                return False
        
        for transition in self.transitions:
            if transition.from_state == self.current_state and transition.event_type == event.type:
                if transition.action:
                    transition.action(event)
                self.current_state = transition.to_state
                return True
        
        if self.current_state in self.state_handlers:
            handler = self.state_handlers[self.current_state]
            new_state = handler(event)
            if new_state:
                self.current_state = new_state
                return True
        
        return False
    
    def _transition_to(self, new_state: State, event: Event) -> bool:
        print(f"Transition: {self.current_state} -> {new_state} (event: {event.type})")
        self.current_state = new_state
        return True
    
    def get_history(self) -> List[tuple[State, Event]]:
        return self.history.copy()
    
    def reset(self, initial_state: State):
        self.current_state = initial_state
        self.history.clear()

class Connection:
    def __init__(self):
        self.machine = StateMachine(State.DISCONNECTED)
        self._setup_transitions()
    
    def _setup_transitions(self):
        self.machine.add_transition(
            State.DISCONNECTED, 
            EventType.CONNECT, 
            State.CONNECTING,
            action=lambda e: print("Starting connection...")
        )
        
        self.machine.add_transition(
            State.ERROR,
            EventType.CONNECT,
            State.RECONNECTING
        )
    
    def connect(self):
        return self.machine.process_event(Event(EventType.CONNECT))
    
    def disconnect(self):
        return self.machine.process_event(Event(EventType.DISCONNECT))
    
    def send(self, message: str):
        return self.machine.process_event(Event(EventType.SEND_MESSAGE, data=message))
    
    def receive(self, message: str):
        return self.machine.process_event(Event(EventType.RECEIVE_MESSAGE, data=message))
    
    @property
    def state(self) -> State:
        return self.machine.current_state

def simulate_connection():
    conn = Connection()
    
    print(f"Initial state: {conn.state}")
    
    conn.connect()
    print(f"After connect: {conn.state}")
    
    conn.receive('connected')
    print(f"After connection established: {conn.state}")
    
    conn.send('Hello, server!')
    
    conn.disconnect()
    print(f"After disconnect: {conn.state}")
    
    history = conn.machine.get_history()
    print(f"\nEvent history ({len(history)} events):")
    for state, event in history:
        print(f"  {state.name}: {event.type.name}")

if __name__ == '__main__':
    simulate_connection()
