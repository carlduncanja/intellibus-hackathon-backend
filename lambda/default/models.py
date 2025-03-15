from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class User:
    Id: str
    Tokens: str


@dataclass
class Message:
    Id: str
    UserId: str
    Text: Optional[str] = None
    IncludedInModel: bool = False
    AssetKey: Optional[str] = None
    MessageType: Optional[str] = None
    ReplyId: Optional[str] = None
    DateCreated: Optional[str] = None


@dataclass
class Chat:
    Id: str
    Name: str
    AdminId: Optional[str] = None
    AdminName: Optional[str] = None
    ShareId: Optional[str] = None
    Participants: Optional[List[str]] = field(default_factory=list)
    DateCreated: Optional[str] = None
    Messages: Optional[List[Message]] = field(default_factory=list)


@dataclass
class Itinerary:
    Id: str
    AssetKey: str
    ChatId: str
    Name: Optional[str] = None


@dataclass
class Schedule:
    Id: str
    Name: str
    ItineraryId: str
    Description: str
    Link: str
    UserId: str
    Date: str


@dataclass
class SocketConnection:
    ConnectionId: str
    ChatId: str


@dataclass
class Promotion:
    Id: str
    Name: str
    Description: str
    Latitude: float
    Longitude: float
    PromotionRadius: float


@dataclass
class Request:
    Action: str
    ChatId: Optional[str] = None
    UserId: Optional[str] = None
    Chat: Optional[Chat] = None
    Message: Optional[Message] = None
