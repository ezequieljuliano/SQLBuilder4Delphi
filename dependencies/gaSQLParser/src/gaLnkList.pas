{******************************************************************************}
{                                                                              }
{       ga SQL Parser package                                                  }
{       gaDoubleLinklist classes for internal data storage                     }
{                                                                              }
{       Copyright (c) 2001, 2002 AS Gaiasoft                                   }
{       Portions copyright (c) Julian M Bucknall, from Algorithms Alfresco in  }
{       The Delphi Magazine (www.thedelphimagazine.com)                        }
{                                                                              }
{       Redesigned by Gert Kello                                               }
{                                                                              }
{******************************************************************************}

//: Unit for gaLinkList classes 
{:
Unit for gaLinkList and gaListBookmark classes
}
unit gaLnkList;

interface

uses
  SysUtils, Classes;

type
  TgaNodeNotification = (nnAdded, nnDeleted, nnCleared);
  TgaAfftectedNode = (anThisNode, anPreviousNode, anNextNode);
  TgaNotificationPass = (npFirstPass, npSecondPass);

type
  TgaListBaseObject = class;

  PdllNotifyRecord = ^TdllNotifyRecord;
  TdllNotifyRecord = packed record
    dllNextNotifier: PdllNotifyRecord;
    dllRequester: TgaListBaseObject;
    dllNotifyPass: TgaNotificationPass;
  end;

  PdllNode = ^TdllNode;
  TdllNode = packed record
    dllnNext : PdllNode;
    dllnPrev : PdllNode;
    dllnData : Pointer;
    dllnNotifiers: PdllNotifyRecord;
  end;

  TgaListBaseObject = class (TObject)
  protected
    procedure DataOwnerDestroyed; virtual;
    procedure NodeInfoChange(ANode: PdllNode; Action: TgaNodeNotification; 
            AffectedNode: TgaAfftectedNode); virtual;
  end;
  
  //: Abstract list bookmark class 
  {:
  Abstract base class for list bookmarks.
  Contains properties to determ wheter the bookmark is valid or not and to get
  read/write access to the item pointed by bookmark.
  Descendants of the class should at least override the access methods
  GetIsValid, GetItem and SetItem.
  They would propably need to add property to store the bookmark pointer and
  the list for which the bookmark is created.
  }
  TgaListBookmark = class (TgaListBaseObject)
  protected
    //: GetIsValid is the abstract read access method of the IsValid property. 
    function GetIsValid: Boolean; virtual; abstract;
    //: GetItem is the read access method of the Item property 
    function GetItem: Pointer; virtual; abstract;
    //: SetItem is the write access method of the Item property. 
    procedure SetItem(Value: Pointer); virtual; abstract;
  public
    function BOF: Boolean; virtual; abstract;
    function EOF: Boolean; virtual; abstract;
    procedure First; virtual; abstract;
    procedure Last; virtual; abstract;
    procedure Next; virtual; abstract;
    procedure Previous; virtual; abstract;
    //: Property IsValid determs whether the bookmark is valid or not 
    {:
    Property IsValid is read and run time only.
    It determs whether the bookmark is valid or not.
    }
    property IsValid: Boolean read GetIsValid;
    //: Property Item gives an read/write access to the item represented by the bookmark 
    {:
    Property Item is read / write, at run time only.
    It gives an read/write access to the item represented by the cursor.
    The descendants are required to implement the access methods GetItem and
    SetItem.
    }
    property Item: Pointer read GetItem write SetItem;
  end;
  
  TgaSimpleDoubleList = class (TgaListBaseObject)
  private
    {:
    Field FDataUserList.
    }
    FDataUserList: PdllNotifyRecord;
    //: FHead is the state field of the Head property. 
    {:
    FHead is the state field of the Head property.
    }
    FHead: PdllNode;
    {:
    FTail is the state field of the Tail property.
    }
    FTail: PdllNode;
    procedure InternalDispatchNodeChange(ANode: PdllNode; Action: 
            TgaNodeNotification; AffectedNode: TgaAfftectedNode; NotifierList: 
            PdllNotifyRecord; NotifyPass: TgaNotificationPass);
  protected
    procedure FreeDataUserList;
    procedure AddDataUser(ADataUser: TgaListBaseObject; ANotifyPass: 
            TgaNotificationPass); virtual;
    procedure RemoveDataUser(ADataUser: TgaListBaseObject); virtual;
    procedure AddNodeChangeListener(ANode: PdllNode; AListener: 
            TgaListBaseObject; ANotifyPass: TgaNotificationPass); virtual;
    procedure DispatchNodeChange(ANode: PdllNode; Action: TgaNodeNotification; 
            AffectedNode: TgaAfftectedNode);
    procedure InitDoubleList; virtual;
    procedure InternalDelete(ANode: PdllNode);
    function InternalInsert(AItem : pointer; AInsertItem: PdllNode): PdllNode;
    class function IsList(AHead, ATail: PdllNode): Boolean;
    function IsNodeInside(ANode: PdllNode): Boolean;
    function NodeOf(AItem: pointer): PdllNode;
    procedure Notify(Ptr: Pointer; Action: TListNotification); virtual;
    procedure NotifyNodeChange(ANode: PdllNode; Action: TgaNodeNotification); 
            virtual;
    procedure NotifyNodeDataChange(AOldItem, ANewItem: pointer);
    procedure RemoveNodeChangeListener(ANode: PdllNode; AListener: 
            TgaListBaseObject); virtual;
    procedure SetHeadNode(AHead: PdllNode); virtual;
    procedure SetNodeData(ANode: PdllNode; AData: Pointer);
    procedure SetTailNode(ATail: PdllNode); virtual;
    {:
    Property Head is read only.
    }
    property Head: PdllNode read FHead;
    {:
    Property Tail is read only.
    It represents the node after the last node in the list.
    If List has a cursor then Eof := Cursor = Tail;
    }
    property Tail: PdllNode read FTail;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; virtual;
  end;
  
  //: Bookmark for the TgaDoubleList, TgaSharedDoubleList and their descendants 
  {:
  TgaDoubleListBookmark implements abstract methods (GetIsValid, GetItem and
  SetItem) of the TgaListBookmark. It implements functionality to work as
  Bookmark for TgaDoubleLinkList, TgaSharedDoubleLinkList and their descendants.
  }
  TgaDoubleListBookmark = class (TgaListBookmark)
  private
    {:
    FCursor is the state field of the Cursor property.
    }
    FCursor: PdllNode;
    FIsValid: Boolean;
    {:
    FOwnerList is the state field of the OwnerList property.
    }
    FOwnerList: TgaSimpleDoubleList;
  protected
    procedure DataOwnerDestroyed; override;
    //: Overrides abstarct TgaListBookmark.GetIsValid 
    function GetIsValid: Boolean; override;
    //: Function GetItem overrides abstract GetItem 
    function GetItem: Pointer; override;
    function IsValidFor(AList: TgaSimpleDoubleList): Boolean; virtual;
    procedure NodeInfoChange(ANode: PdllNode; Action: TgaNodeNotification; 
            AffectedNode: TgaAfftectedNode); override;
    procedure SetCursor(ACursor: PdllNode);
    procedure SetItem(Value: Pointer); override;
    {:
    Property Cursor is read only.
    }
    property Cursor: PdllNode read FCursor;
    {:
    Property OwnerList is read only.
    }
    property OwnerList: TgaSimpleDoubleList read FOwnerList;
  public
    constructor Create(AOwnerList: TgaSimpleDoubleList; ANode: PdllNode);
    destructor Destroy; override;
    function BOF: Boolean; override;
    function EOF: Boolean; override;
    procedure First; override;
    procedure Last; override;
    procedure Next; override;
    procedure Previous; override;
    procedure Reset;
    procedure Syncronize(ABookmark: TgaDoubleListBookmark);
  end;
  
  TgaDoubleList = class (TgaSimpleDoubleList)
  private
    {:
    FCount is the state field of the Count property.
    }
    FCount: Integer;
    FCursorObj: TgaDoubleListBookmark;
    function GetBof: Boolean;
    function GetCursor: PdllNode;
    function GetEof: Boolean;
    function GetFirstItem: Pointer;
    function GetLastItem: Pointer;
    procedure SetFirstItem(Value: Pointer);
    procedure SetLastItem(Value: Pointer);
  protected
    function Extract(Item: Pointer): Pointer;
    function GetCurrentItem: Pointer; virtual;
    function GetIsEmpty: Boolean; virtual;
    procedure InitDoubleList; override;
    function IsCursorCorrect: Boolean;
    procedure NotifyNodeChange(ANode: PdllNode; Action: TgaNodeNotification); 
            override;
    procedure SetCurrentItem(Value: Pointer); virtual;
    {:
    Property Cursor is read only.
    }
    property Cursor: PdllNode read GetCursor;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(Item: Pointer); virtual;
    procedure CopyListContest(ACopyList: TgaDoubleList); virtual;
    procedure DeleteCurrent;
    procedure First;
    function GetBookmark: TgaDoubleListBookmark; virtual;
    procedure GotoBookmark(ABookmark: TgaDoubleListBookmark);
    procedure InsertAfterCurrent(AItem: Pointer; MoveCursorToNewItem: boolean); 
            virtual;
    procedure Last;
    function Locate(AItem: Pointer): Boolean;
    procedure Next;
    procedure Pack;
    procedure Previous;
    procedure Remove(Item: Pointer);
    {:
    Property Bof is read and run time only.
    }
    property Bof: Boolean read GetBof;
    {:
    Property Count is read and run time only.
    }
    property Count: Integer read FCount;
    {:
    Property CurrentItem is read / write, at run time only.
    }
    property CurrentItem: Pointer read GetCurrentItem write SetCurrentItem;
    {:
    Property Eof is read and run time only.
    }
    property Eof: Boolean read GetEof;
    {:
    Property FirstItem is read / write, at run time only.
    }
    property FirstItem: Pointer read GetFirstItem write SetFirstItem;
    {:
    Property IsEmpty is read and run time only.
    }
    property IsEmpty: Boolean read GetIsEmpty;
    {:
    Property LastItem is read / write, at run time only.
    }
    property LastItem: Pointer read GetLastItem write SetLastItem;
  end;
  
  TgaSharedDoubleList = class (TgaDoubleList)
  private
    {:
    FDataOwner is the state field of the DataOwner property.
    }
    FDataOwner: TgaDoubleList;
    FChangeInThisList: Boolean;
    {:
    FIsDataOwner is the state field of the IsDataOwner property.
    }
    FIsDataOwner: Boolean;
    FStrictEndPos: Boolean;
    FStrictStartPos: Boolean;
  protected
    procedure DataOwnerDestroyed; override;
    procedure InitDoubleList; override;
    procedure AddDataUser(ADataUser: TgaListBaseObject; ANotifyPass: 
            TgaNotificationPass); override;
    procedure AddNodeChangeListener(ANode: PdllNode; AListener: 
            TgaListBaseObject; ANotifyPass: TgaNotificationPass); override;
    procedure NodeInfoChange(ANode: PdllNode; Action: TgaNodeNotification; 
            AffectedNode: TgaAfftectedNode); override;
    //: Calls Dataowners Notify in addition if the list is mirroring list 
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
    //: Calls inherited if IsDataOwner, otherwise calls DataOwners NotifyNodeChange 
    procedure NotifyNodeChange(ANode: PdllNode; Action: TgaNodeNotification); 
            override;
    procedure RemoveDataUser(ADataUser: TgaListBaseObject); override;
    procedure RemoveNodeChangeListener(ANode: PdllNode; AListener: 
            TgaListBaseObject); override;
    procedure SetHeadNode(ANode: PdllNode); override;
    procedure SetTailNode(ANode: PdllNode); override;
  public
    constructor Create;
    constructor CreateMirror(AMirroredList: TgaDoubleList);
    destructor Destroy; override;
    procedure SetEndPos(APositionedList: TgaDoubleList; AStrictEndPos: Boolean);
    procedure SetStartPos(APositionedList: TgaDoubleList; AStrictStartPos: 
            boolean);
    procedure Add(Item: Pointer); override;
    procedure Clear; override;
    //: procedure InsertAfterCurrent overrides inherited InsertAfterCurrent. 
    procedure InsertAfterCurrent(AItem: Pointer; MoveCursorToNewItem: boolean); 
            override;
    {:
    Property DataOwner is read and run time only.
    if DataOwner = Self, then IsDataOwner = True;
    the IsDataOwner and IsDataOwner proeprties are set in the constructor and
    can't be changed during the life of the list
    }
    property DataOwner: TgaDoubleList read FDataOwner;
    {:
    Property IsDataOwner is read and run time only.
    }
    property IsDataOwner: Boolean read FIsDataOwner;
    property StrictEndPos: Boolean read FStrictEndPos;
    property StrictStartPos: Boolean read FStrictStartPos;
  end;
  

  EgaLinkListError = class (Exception)
  end;
  
  EgaListBookmarkError = class (Exception)
  end;
  
implementation

resourcestring
// START resource string wizard section
  SCanTAddMasterListToTheDataUsersList = 'Can''t add master list to the data users list';
  SChangingHeadNodeNotAllowed = 'Changing Head node not allowed';
  SChangingTailNodeNotAllowed = 'Changing Tail node not allowed';
  SListIsNotAMirroringList = 'List is not a mirroring list: %s';
  SListsDoNotShareData = 'Lists do not share data: %s';
  SInvalidBookmark = 'Invalid bookmark: %s';
  SCantSetTheStartOrEndPostions = 'Can''t set the start or end postions';
  SCantGetItem = 'Can''t get the item';
  SCantSetItem = 'Can''t set the item';
  SInvalidCursor = 'New cursor is not part of the list';
  SNoHeadNode = 'Invalid link list - no head node';
  SNoCurrentItemForTheOperation = 'Either Bof or Eof is true - no current item for the operation';
  SCannotDeleteHeadOrTailNode = 'Can''t delete Head or Tail node';
  SNoItemsInTheList = 'There is no items in the list';
// END resource string wizard section

procedure dnmFreeNode(aNode : PdllNode);
begin
  Dispose(aNode);
end;

function dnmAllocNode : PdllNode;
begin
  New(Result);
  FillChar(Result^, SizeOf(Result^), 0);
end;

procedure dnmFreeNotifier(aNode : PdllNotifyRecord);
begin
  Dispose(aNode);
end;

function dnmAllocNotifier : PdllNotifyRecord;
begin
  New(Result);
  FillChar(Result^, SizeOf(Result^), 0);
end;

{
***************************** TgaSimpleDoubleList ******************************
}
constructor TgaSimpleDoubleList.Create;
{:
Constructor Create overrides the inherited Create.
First inherited Create is called, then the internal data structure is
initialized via call to InitDoubleList;
}
begin
  inherited Create;
  InitDoubleList;
end;

destructor TgaSimpleDoubleList.Destroy;
{:
Destructor Destroy overrides the inherited Destroy.
First the Clear methodis called, then all owned fields are free'd,
finally inherited Destroy is called.
}
begin
  { FreeDataUserList will also free FActiveDataUserList. And if the DataUserList
    is unassigned, then the ActiveDataUserList should also be.. }
  if FDataUserList <> nil then
    FreeDataUserList;
  Clear;
  if Head <> nil then
    dnmFreeNode(Head);
  if Tail <> nil then
    dnmFreeNode(Tail);
  inherited Destroy;
end;

procedure TgaSimpleDoubleList.AddDataUser(ADataUser: TgaListBaseObject; 
        ANotifyPass: TgaNotificationPass);
{:
procedure AddDataUser - Adds a list to the internal DataUsers list, so that it
can be notified if the DataOwner is destroyed. Called (normally) from the
TgaSharedDoubleLinkList.CreateMirror.
}
var
  tmpHolder: PdllNotifyRecord;
begin
  Assert(ADataUser <> Self);
  tmpHolder := dnmAllocNotifier;
  tmpHolder.dllRequester := ADataUser;
  tmpHolder.dllNextNotifier := FDataUserList;
  tmpHolder.dllNotifyPass := ANotifyPass;
  FDataUserList := tmpHolder;
end;

procedure TgaSimpleDoubleList.AddNodeChangeListener(ANode: PdllNode; AListener: 
        TgaListBaseObject; ANotifyPass: TgaNotificationPass);
var
  cnHolder: PdllNotifyRecord;
begin
  if ANode = nil then
    Exit;
  Assert(AListener <> nil);
  cnHolder := dnmAllocNotifier;
  cnHolder.dllRequester := AListener;
  cnHolder.dllNextNotifier := ANode.dllnNotifiers;
  cnHolder.dllNotifyPass := ANotifyPass;
  ANode.dllnNotifiers := cnHolder;
end;

procedure TgaSimpleDoubleList.Clear;
{:
procedure Clear.
Clears the contest of the list.
It first calls NotifyNodeChange with nil ChangedNode (to indicate that zero
or more nodes might be affected) and nnCleared action. Then, for every
item in the list, the holding node is removed and Notify is called to indicate
that the item has been deleted.
This form of clear is not allowed for mirroring lists - they must not call
NotifyNodeChange with nnCleared flag.
}
var
  Temp: PdllNode;
  tmpData: Pointer;
begin
  if Head <> nil then
  begin
    { There is no need to correct list state here - this form of clear can be
      executed *ONLY* if the list is master list }
    NotifyNodeChange(nil, nnCleared);
    Temp := Head.dllnNext;
    while (Temp <> Tail) do begin
      Head.dllnNext := Temp.dllnNext;
      tmpData := Temp.dllnData;
      dnmFreeNode(Temp);
      if tmpData <> nil then
        Notify(tmpData, lnDeleted);
      Temp := Head.dllnNext;
    end;
    Tail.dllnPrev := Head;
  end;
end;

procedure TgaSimpleDoubleList.DispatchNodeChange(ANode: PdllNode; Action: 
        TgaNodeNotification; AffectedNode: TgaAfftectedNode);
var
  lNotifyPass: TgaNotificationPass;
begin
  Assert(Self <> nil);
  Assert(ANode <> nil);
  for lNotifyPass := Low(lNotifyPass) to High(lNotifyPass) do
    InternalDispatchNodeChange(ANode, Action, AffectedNode, ANode.dllnNotifiers, lNotifyPass);
end;

procedure TgaSimpleDoubleList.FreeDataUserList;
{:
procedure FreeDataUserList - Notifies all data users that the master list is
about to be destroyed. Clears and frees the FDataUserList and
FActiveDataUserList.
}
var
  tmpHolder: PdllNotifyRecord;
begin
  while FDataUserList <> nil do
  begin
    tmpHolder := FDataUserList;
    Assert(tmpHolder.dllRequester <> Self);
    tmpHolder.dllRequester.DataOwnerDestroyed;
    Assert(tmpHolder <> FdataUserList);
  end;
end;

procedure TgaSimpleDoubleList.InitDoubleList;
{:
procedure InitDoubleList.
Allocates Head and Tail node and initializes them to form a list
}
begin
  {allocate a head and a tail node}
  FHead := dnmAllocNode;
  FTail := dnmAllocNode;
  Head.dllnNext := Tail;
  Tail.dllnPrev := Head;
end;

procedure TgaSimpleDoubleList.InternalDelete(ANode: PdllNode);
{:
procedure InternalDelete.
ANode - A node to be deleted.
First the node is removed from list.
Then the list is notified about the node change (call to NotifyNodeChange)
After the that node is disposed and Notify is called for Nodes Data (item)
pointer
All list deletions should be done trough this method (the Clear is exeception).
}
var
  tmpData: Pointer;
begin
  if (ANode = Head) or (ANode = Tail) then
    raise EgaLinkListError.Create(SCannotDeleteHeadOrTailNode);
  tmpData := ANode.dllnData;
  ANode.dllnPrev.dllnNext := ANode.dllnNext;
  ANode.dllnNext.dllnPrev := ANode.dllnPrev;
  NotifyNodeChange(ANode, nnDeleted);
  dnmFreeNode(ANode);
  if tmpData <> nil then
    Notify(tmpData, lnDeleted);
end;

procedure TgaSimpleDoubleList.InternalDispatchNodeChange(ANode: PdllNode; 
        Action: TgaNodeNotification; AffectedNode: TgaAfftectedNode; 
        NotifierList: PdllNotifyRecord; NotifyPass: TgaNotificationPass);
var
  tmpNotifierList: PdllNotifyRecord;
begin
  while NotifierList <> nil do
  begin
    // Must store the next notifier before message dispatch, as the current
    // notifier might be freed meanwhile...
    tmpNotifierList := NotifierList;
    NotifierList := tmpNotifierList.dllNextNotifier;
    if tmpNotifierList.dllNotifyPass = NotifyPass then
      tmpNotifierList.dllRequester.NodeInfoChange(ANode, Action, AffectedNode);
  end;
end;

function TgaSimpleDoubleList.InternalInsert(AItem : pointer; AInsertItem: 
        PdllNode): PdllNode;
{:
function InternalInsert.
AItem - A pointer to item to be inserted to the list,
AInsertItem - A item after which the new item is inserted.
Returns: A node which holds the e new item.
All list additions should be done trough this method.
}
begin
  if (AInsertItem = Tail) then
    AInsertItem := AInsertItem.dllnPrev;
  {allocate a new node and insert after the AInsertItem}
  Result := dnmAllocNode;
  Result.dllnData := aItem;
  Result.dllnNext := AInsertItem^.dllnNext;
  Result.dllnPrev := AInsertItem;
  AInsertItem.dllnNext := Result;
  Result.dllnNext.dllnPrev := Result;
  NotifyNodeChange(Result, nnAdded);
  if AItem <> nil then
    Notify(AItem, lnAdded);
end;

class function TgaSimpleDoubleList.IsList(AHead, ATail: PdllNode): Boolean;
{:
class function IsList - checks whether two nodes are connected.
AHead, ATail - nodes to be tested for connectivity.
Returns: True, if it is possible to walk from the AHead node to the ATail node.
}
var
  tmpNode: PdllNode;
begin
  tmpNode := AHead;
  while (tmpNode <> nil) and (tmpNode <> ATail) do
    tmpNode := tmpNode.dllnNext;
  Result := tmpNode = ATail;
end;

function TgaSimpleDoubleList.IsNodeInside(ANode: PdllNode): Boolean;
{:
function IsNodeInside - checks whether the node is inside the list.
ANode - a node to be tested.
Returns: True, if the Node is between the Head and Tail
nodes (inclusive). Head and Tail nodes are considered to be inside the list
}
var
  tmpCursor: PdllNode;
  tmpTail: PdllNode;
begin
  Assert(IsList(Head, Tail));
  tmpCursor := Head;
  tmpTail := Tail;
  if (tmpCursor <> nil) and (ANode <> nil) then
  begin
    while (tmpCursor <> ANode) and (tmpCursor <> tmpTail) do
    begin
      Assert(tmpCursor <> nil);
      tmpCursor := tmpCursor.dllnNext;
    end;
    Result := tmpCursor = ANode;
  end else
    Result := False;
end;

function TgaSimpleDoubleList.NodeOf(AItem: pointer): PdllNode;
{:
function NodeOf - finds a first node that holds a item pointer.
AItem - pointer which is searched for.
Returns: pointer to the first node, that holds the AItem.
}
var
  tmpTail: PdllNode;
begin
  if Head = nil then
    raise EgaLinkListError.Create(SNoHeadNode);
  Result := Head.dllnNext;
  tmpTail := Tail;
  while (Result <> tmpTail) and (Result.dllnData <> AItem) do
    Result := Result.dllnNext;
  if Result = tmpTail then
    Result := nil;
end;

procedure TgaSimpleDoubleList.Notify(Ptr: Pointer; Action: TListNotification);
{:
procedure Notify. Notify is called each time the logical contest of list
changes. Logical Conetnts means the set of items the form the list. In example,
adding or removing nil item is not considered to be an change in logical
conents, but replacing a item with another one is.
Ptr - pointer to the item for which the Action is performed.
}
begin
  ;// Do nothing here
end;

procedure TgaSimpleDoubleList.NotifyNodeChange(ANode: PdllNode; Action: 
        TgaNodeNotification);
{:
procedure NotifyNodeChange - A method that is meant for checking internal data
dependencies, for example whtere the node being removed is cursor or not.
ANode - the node that is affected by the Action.
Tere is no dependecies to check in TgaSimpleDoubleList.
}
var
  lNotifyPass: TgaNotificationPass;
begin
  if Action in [nnAdded, nnDeleted] then
  begin
    DispatchNodeChange(ANode, Action, anThisNode);
    DispatchNodeChange(ANode.dllnNext, Action, anPreviousNode);
    DispatchNodeChange(ANode.dllnPrev, Action, anNextNode);
  end else
  for lNotifyPass := Low(lNotifyPass) to High(lNotifyPass) do
    InternalDispatchNodeChange(ANode, Action, anThisNode, FDataUserList, lNotifyPass);
end;

procedure TgaSimpleDoubleList.NotifyNodeDataChange(AOldItem, ANewItem: pointer);
{:
NotifySwap calls lnDeleted notify for AOldItem, if assigned, and lnAdded notify 
for ANewItem, if Assigned.
}
begin
  if AOldItem <> ANewItem then
  begin
    if AOldItem <> nil then
      Notify(AOldItem, lnDeleted);
    if ANewItem <> nil then
      Notify(ANewItem, lnAdded);
  end;
end;

procedure TgaSimpleDoubleList.RemoveDataUser(ADataUser: TgaListBaseObject);
{:
procedure RemoveDataUser - removes ADataUser from destroy notify list.
Normally called when the mirror list is destroyed.
if ADataUser is not found in list, the method does nothing.
}
var
  lasttmpHolder, tmpHolder: PdllNotifyRecord;
begin
  lasttmpHolder := FDataUserList;
  if lasttmpHolder = nil then
    Exit;
  if lasttmpHolder.dllRequester = ADataUser then
  begin
    FDataUserList := lasttmpHolder.dllNextNotifier;
    dnmFreeNotifier(lasttmpHolder);
    Exit;
  end;
  tmpHolder := lasttmpHolder.dllNextNotifier;
  while tmpHolder <> nil do
  begin
    if tmpHolder.dllRequester = ADataUser then
    begin
      lasttmpHolder.dllNextNotifier := tmpHolder.dllNextNotifier;
      dnmFreeNotifier(tmpHolder);
      Exit;
    end;
    lasttmpHolder := tmpHolder;
    tmpHolder := tmpHolder.dllNextNotifier;
  end;
end;

procedure TgaSimpleDoubleList.RemoveNodeChangeListener(ANode: PdllNode; 
        AListener: TgaListBaseObject);
var
  lasttmpHolder, tmpHolder: PdllNotifyRecord;
begin
  if ANode = nil then
    Exit;
  Assert(AListener <> nil);
  lasttmpHolder := ANode.dllnNotifiers;
  Assert(lasttmpHolder <> nil);
  if lasttmpHolder.dllRequester = AListener then
  begin
    ANode.dllnNotifiers := lasttmpHolder.dllNextNotifier;
    dnmFreeNotifier(lasttmpHolder);
    Exit;
  end;
  tmpHolder := lasttmpHolder.dllNextNotifier;
  while tmpHolder <> nil do
  begin
    if tmpHolder.dllRequester = AListener then
    begin
      lasttmpHolder.dllNextNotifier := tmpHolder.dllNextNotifier;
      dnmFreeNotifier(tmpHolder);
      Exit;
    end;
    lasttmpHolder := tmpHolder;
    tmpHolder := tmpHolder.dllNextNotifier;
  end;
  Assert(False);
end;

procedure TgaSimpleDoubleList.SetHeadNode(AHead: PdllNode);
begin
  Assert (False, SChangingHeadNodeNotAllowed);
end;

procedure TgaSimpleDoubleList.SetNodeData(ANode: PdllNode; AData: Pointer);
var
  tmpItem: Pointer;
begin
  Assert(ANode <> Head);
  Assert(ANode <> Tail);
  Assert(IsNodeInside(ANode));
  tmpItem := ANode.dllnData;
  if tmpItem <> AData then
  begin
    ANode.dllnData := AData;
    NotifyNodeDataChange(tmpItem, AData);
  end;
end;

procedure TgaSimpleDoubleList.SetTailNode(ATail: PdllNode);
begin
  Assert (False, SChangingTailNodeNotAllowed);
end;

{
******************************** TgaDoubleList *********************************
}
constructor TgaDoubleList.Create;
begin
  inherited Create;
  FCursorObj := TgaDoubleListBookmark.Create(Self, Head);
end;

destructor TgaDoubleList.Destroy;
{:
Destructor Destroy overrides the inherited Destroy.
First the Cursor is cleared (to avoid problems in Clear), then the DataUserList
checked for and freed if present, finally inherited Destroy is called.
}
begin
  FCursorObj.Free;
  inherited Destroy;
end;

procedure TgaDoubleList.Add(Item: Pointer);
{:
procedure Add - Adds a item at the end of the list.
Item - item to be added.
}
begin
  InternalInsert(Item, Tail);
end;

procedure TgaDoubleList.CopyListContest(ACopyList: TgaDoubleList);
{:
procedure CopyListContest - Clears self and then adds all items from the
ACopyList to the self.
}
begin
  Clear;
  ACopyList.First;
  while not ACopyList.Eof do
  begin
    Add(ACopyList.CurrentItem);
    ACopyList.Next;
  end;
end;

procedure TgaDoubleList.DeleteCurrent;
{:
procedure DeleteCurrent - deletes the item represented by the cursor from the
list.
}
begin
  if Eof or Bof then
    raise EgaLinkListError.Create(SNoCurrentItemForTheOperation);
  InternalDelete(Cursor);
end;

function TgaDoubleList.Extract(Item: Pointer): Pointer;
{:
function Extract - removes the item from the list, but with lnExtracted
notification rather than lnDeleted notification.
Item - a item to be deleted.
Returns: Item, if the item was found from the list.
Nil, if the item was not found from the list.
}
var
  tmpNode: PdllNode;
begin
  Result := nil;
  tmpNode := NodeOf(Item);
  if tmpNode <> nil then
  begin
    Result := Item;
    tmpNode.dllnData := nil;
    InternalDelete(tmpNode);
    Notify(Result, lnExtracted);
  end;
end;

procedure TgaDoubleList.First;
{:
procedure First - sets the cursor to point to the first item in the list.
If the list is empty, the item will be the Tail item. After the call to the
First method, the BOF is always False (but Eof might be true, in the case of
empty list).
}
begin
  FCursorObj.First;
end;

function TgaDoubleList.GetBof: Boolean;
{:
GetBof is the read access method of the Bof property.
Results true if the cursor is positioned at the head (before the first) node
of the list.
}
begin
  Result := FCursorObj.Bof
end;

function TgaDoubleList.GetBookmark: TgaDoubleListBookmark;
{:
function GetBookmark - generates the bookamark for the current item in the list.
Returns: Bookmark that was generated.
}
begin
  Result := TgaDoubleListBookmark.Create(Self, Cursor);
end;

function TgaDoubleList.GetCurrentItem: Pointer;
{:
GetCurrentItem is the read access method of the CurrentItem property.
There are no current item if the list is either at the Head or Tail node.
}
begin
  if Eof or Bof then
    raise EgaLinkListError.Create(SNoCurrentItemForTheOperation);
  Result := Cursor.dllnData;
end;

function TgaDoubleList.GetCursor: PdllNode;
{:
SetItem is the write access method of the Item property.
It changes the value of the item represented by the cursor. The method has 
to be overridden by the descendant classes.
}
begin
  Result := FCursorObj.Cursor;
end;

function TgaDoubleList.GetEof: Boolean;
{:
GetEof is the read access method of the Eof property.
Results true if the cursor is positioned at the tail (after the last) node
of the list.
}
begin
  Result := FCursorObj.Eof;
end;

function TgaDoubleList.GetFirstItem: Pointer;
{:
GetFirstItem is the read access method of the FirstItem property.
It resturns the first item (the one after the Head node) in the list.
If the list is empty, the exeception is raised
}
begin
  if IsEmpty then
    raise EgaLinkListError.Create(SNoItemsInTheList);
  Result := Head.dllnNext.dllnData;
end;

function TgaDoubleList.GetIsEmpty: Boolean;
{:
GetIsEmpty is the read access method of the IsEmpty property.
A list is empty, if the next node after the Head is the Tail node.
}
begin
  Result := Head.dllnNext = Tail;
end;

function TgaDoubleList.GetLastItem: Pointer;
{:
GetLastItem is the read access method of the LastItem property.
It returns the last item (the one before the Tail node) in the list.
If the list is empty, the exeception is raised.
}
begin
  if IsEmpty then
    raise EgaLinkListError.Create(SNoItemsInTheList);
  Result := Tail.dllnPrev.dllnData;
end;

procedure TgaDoubleList.GotoBookmark(ABookmark: TgaDoubleListBookmark);
{:
procedure GotoBookmark - postions the current item of the list to the item
represented by the ABookmark. The ABookmark must be obtained from the same list
as GotoBookamrk is called, or the lists must share the data (they must have
common DataOwner).
The CheckListBorders is called to ensure that the list represents valid set of
data.
}
begin
  FCursorObj.Syncronize(ABookmark);
end;

procedure TgaDoubleList.InitDoubleList;
{:
procedure InitDoubleList overrides inherited InitDoubleList.
It first calls inherited InitDaoubleList, after that Count is initialised.
}
begin
  inherited InitDoubleList;
  FCount := 0;
end;

procedure TgaDoubleList.InsertAfterCurrent(AItem: Pointer; MoveCursorToNewItem: 
        boolean);
{:
procedure InsertAfterCurrent - Inserts a item represented by the AItem after the
cursor. If MoveCursorToNewItem = True, then the cursor is moved to the item
inserted.
}
begin
  if MoveCursorToNewItem then
    FCursorObj.SetCursor(InternalInsert(AItem, Cursor))
  else
    InternalInsert(AItem, Cursor);
end;

function TgaDoubleList.IsCursorCorrect: Boolean;
{:
function IsCursorCorrect - Returns a boolean indicating whether the node
pointed by the cursor is inside the list or .
}
begin
  Result := IsList(Head, Tail) and IsNodeInside(Cursor);
end;

procedure TgaDoubleList.Last;
{:
procedure Last - sets the cursor to point to the last item in the list.
If the list is empty, the item will be the Head item. After the call to the
last method, the EOF is always False (but Bof might be true, in the case of
empty list).
}
begin
  FCursorObj.Last;
end;

function TgaDoubleList.Locate(AItem: Pointer): Boolean;
{:
function Locate -  postions cursor to the first node that contains AItem, if
one exists. If the node is found, it returns True. If not, it returns False.
}
var
  tmpCursor: PdllNode;
begin
  tmpCursor := NodeOf(AItem);
  if tmpCursor <> nil then
  begin
    FCursorObj.SetCursor(tmpCursor);
    Result := True;
  end else
    Result := False;
end;

procedure TgaDoubleList.Next;
{:
procedure Next moves the cursor to the next item on the list. If cursor is
already at the end of the list, it deos nothing.
}
begin
  FCursorObj.Next;
end;

procedure TgaDoubleList.NotifyNodeChange(ANode: PdllNode; Action: 
        TgaNodeNotification);
{:
procedure NotifyNodeChange overrides inherited NotifyNodeChange calls inherited
NotifyNodeChange.
In addition, it corrects the item count of the list, changes cursor if required,
increments Node Revision ID and notifies Active mirroring lists about the
change.
}
begin
  inherited NotifyNodeChange(ANode, Action);
  { correct the list item count }
  case Action of
    nnAdded:
      Inc(FCount);
    nnDeleted:
      Dec(FCount);
    nnCleared:
      FCount := 0;
  end;
end;

procedure TgaDoubleList.Pack;
{:
procedure Pack - removes nil items from the list.
}
var
  tmpCursor: PdllNode;
begin
  tmpCursor := Head.dllnNext;
  while tmpCursor <> Tail do
  begin
    if tmpCursor.dllnData = nil then
    begin
      tmpCursor := tmpCursor.dllnNext;
      InternalDelete(tmpCursor.dllnPrev);
    end else
      tmpCursor := tmpCursor.dllnNext;
  end;
end;

procedure TgaDoubleList.Previous;
{:
procedure Previous moves the cursor to the previous item in the list.
If cursor is already at the beginning of the list, it deos nothing.
}
begin
  FCursorObj.Previous;
end;

procedure TgaDoubleList.Remove(Item: Pointer);
{:
procedure Remove - removes the first copy of the Item from the list.
}
var
  tmpNode: PdllNode;
begin
  tmpNode := NodeOf(Item);
  if tmpNode <> nil then
    InternalDelete(tmpNode);
end;

procedure TgaDoubleList.SetCurrentItem(Value: Pointer);
{:
SetCurrentItem is the write access method of the CurrentItem property.
}
begin
  FCursorObj.Item := Value;
end;

procedure TgaDoubleList.SetFirstItem(Value: Pointer);
{:
SetFirstItem is the write access method of the FirstItem property.
It sets the first item (the one after the Head node) in the list.
If the list is empty, the exeception is raised.
}
begin
  if IsEmpty then
    raise EgaLinkListError.Create(SNoItemsInTheList);
  SetNodeData(Head.dllnNext, Value);
end;

procedure TgaDoubleList.SetLastItem(Value: Pointer);
{:
SetLastItem is the write access method of the LastItem property.
It sets the last item (the one before the Tail node) in the list.
If the list is empty, the exeception is raised.
}
begin
  if IsEmpty then
    raise EgaLinkListError.Create(SNoItemsInTheList);
  SetNodedata(Tail.dllnPrev, Value);
end;

{
***************************** TgaSharedDoubleList ******************************
}
constructor TgaSharedDoubleList.Create;
{:
Constructor Create overrides the inherited Create.
First the internal data structure is initialized to indicate that the list
itself is the owner of the data, then inherited Create is
called.
}
begin
  FDataOwner := Self;
  FIsDataOwner := True;
  inherited Create;
end;

constructor TgaSharedDoubleList.CreateMirror(AMirroredList: TgaDoubleList);
{:
constructor CreateMirror - creates a "mirror" list for the AMirroredList. The
lists will have common dataowner (i.e. if Ythe AMirroredList is itself a mirror,
then the dataowner will be the dataowner of the AMirroredList). Note that the
DataIwner of TgaDoubleList is implicitly the list itself.
The contents of the list will be exactly the same as it is for AMirroredList -
if it has strict last or first item, a new mirror will have the same.
the starting/ening postions can be changed later trough the call to
SetStartPos/SetEndPos.
}
var
  tmpActiveMirror: TgaSharedDoubleList;
begin
  FIsDataOwner := False;
  if AMirroredList is TgaSharedDoubleList then
  begin
    tmpActiveMirror := TgaSharedDoubleList(AMirroredList);
    FDataOwner := tmpActiveMirror.DataOwner;
    FStrictStartPos := tmpActiveMirror.StrictStartPos;
    FStrictEndPos := tmpActiveMirror.StrictEndPos;
  end else
    FDataOwner := AMirroredList;
  DataOwner.AddDataUser(Self, npFirstPass);
  SetHeadNode(AMirroredList.Head);
  SetTailNode(AMirroredList.Tail);
  inherited Create;
  FCursorObj.SetCursor(AMirroredList.Cursor);
end;

destructor TgaSharedDoubleList.Destroy;
{:
Destructor Destroy overrides the inherited Destroy.
If the list is a mirroring list, then the list must be removed from the
(Active)DataUserList of the DataOwner. Also, the Head and Tail must be cleared
to avoid changing the master list.
Finally inherited Destroy is called.
}
begin
  if not IsDataOwner then
  begin
    // Do notify the bookmarks before the list is invalidated
    FreeDataUserList;
    if FDataOwner <> nil then
      FDataOwner.RemoveDataUser(Self);
    SetTailNode(nil);
    SetHeadNode(nil);
    FDataOwner := nil;
  end;
  inherited Destroy;
end;

procedure TgaSharedDoubleList.Add(Item: Pointer);
{:
procedure Add overrides inherited Add.
This method is overridden to allow the strict mirror list to grow, if the
Add method is called on this instance. To do that, the FirstNode and LastNode
are unbound, then inherited Add is called. After that, theese nodes are rebound,
if needed.
}
begin
  FChangeInThisList := True;
  try
  inherited Add(Item);
  finally
    FChangeInThisList := False;
  end;
end;

procedure TgaSharedDoubleList.AddDataUser(ADataUser: TgaListBaseObject; 
        ANotifyPass: TgaNotificationPass);
{:
procedure AddDataUser overrides inherited AddDataUser calls
If the list is not a Data Owner, then an exception is raised to indicate that
mirroring lists can't have data users.
}
begin
  if ADataUser = DataOwner then
    raise EgaLinkListError.Create(SCanTAddMasterListToTheDataUsersList);
  inherited AddDataUser(ADataUser, ANotifyPass);
  if not IsDataOwner then
    DataOwner.AddDataUser(ADataUser, ANotifyPass);
end;

procedure TgaSharedDoubleList.AddNodeChangeListener(ANode: PdllNode; AListener: 
        TgaListBaseObject; ANotifyPass: TgaNotificationPass);
begin
  if IsDataOwner then
    inherited AddNodeChangeListener(ANode, AListener, ANotifyPass)
  else
    DataOwner.AddNodeChangeListener(ANode, AListener, ANotifyPass);
end;

procedure TgaSharedDoubleList.Clear;
{:
procedure Clear overrides inherited Clear.
The inherited Clear is called only if the list is a owner of the data.
If not, the list is emptied item by item.
}
var
  Temp: PdllNode;
  tmpData: Pointer;
begin
  if IsDataOwner then
    inherited Clear
  else begin
    if Head <> nil then
    begin
      Temp := Head.dllnNext;
      while (Temp <> Tail) do begin
        Head.dllnNext := Temp.dllnNext;
        Head.dllnNext.dllnPrev := Head;
        NotifyNodeChange(Temp, nnDeleted);
        tmpData := Temp.dllnData;
        dnmFreeNode(Temp);
        if tmpData <> nil then
          Notify(tmpData, lnDeleted);
        Temp := Head.dllnNext;
      end;
      Assert(Head.dllnNext = Tail);
      Assert(Tail.dllnPrev = Head);
    end;
    // FCount := 0; Do not set the count as for mirror list the count is always -1
  end;
end;

procedure TgaSharedDoubleList.DataOwnerDestroyed;
{:
procedure DataOwnerDestroyed is called when the DataOwner list is destroyed.
As all list data is also destroyed, the list is marked as "invalid"
}
begin
  inherited;
  FreeDataUserList;
  SetHeadNode(nil);
  SetTailNode(nil);
  FStrictStartPos := False;
  FStrictEndPos := False;
  DataOwner.RemoveDataUser(Self);
  FDataOwner := nil;
end;

procedure TgaSharedDoubleList.InitDoubleList;
{:
procedure InitDoubleList overrides inherited InitDoubleList.
If the list is DataOwner, the inherited InitDoubleList is called.
If it is not, the Cursor it inited to the Head node and the Count is set to -1 -
tom indicate that the count is not valid for the mirror list
(all other initialization is done in CreateMirror constructor)
}
begin
  if IsDataOwner then
    inherited InitDoubleList
  else
    FCount := -1;
end;

procedure TgaSharedDoubleList.InsertAfterCurrent(AItem: Pointer; 
        MoveCursorToNewItem: boolean);
{:
procedure InsertAfterCurrent overrides inherited InsertAfterCurrent.
Reason: to allow the mirroring list with strict start or end position to
"absorb" a item if the current item is the last one in the list
}
begin
  FChangeInThisList := True;
  try
    inherited InsertAfterCurrent(AItem, MoveCursorToNewItem)
  finally
    FChangeInThisList := False;
  end;
end;

procedure TgaSharedDoubleList.NodeInfoChange(ANode: PdllNode; Action: 
        TgaNodeNotification; AffectedNode: TgaAfftectedNode);
begin
  inherited NodeInfoChange(ANode, Action, AffectedNode);
  case Action of
    nnAdded: begin
      if not FChangeInThisList then
      begin
        if StrictStartPos and (ANode = Head) and (AffectedNode = anNextNode)
            and (ANode.dllnNext.dllnNext <> Tail) then
            // if ANode.dllnNext.dllnNext = Tail then StrictEndPos determs what to do
          SetHeadNode(Head.dllnNext)
        else if StrictEndPos and (ANode = Tail) and (AffectedNode = anPreviousNode) then
          SetTailNode(Tail.dllnPrev);
      end;
    end;
    nnDeleted: begin
      if AffectedNode = anThisNode then
      begin
        if ANode = Head then
          SetHeadNode(Head.dllnPrev)
        else if ANode = Tail then
          SetTailNode(Tail.dllnNext);
      end;
    end;
    nnCleared: begin
      SetHeadNode(DataOwner.Head);
      SetTailNode(DataOwner.Tail);
    end;
  end;
end;

procedure TgaSharedDoubleList.Notify(Ptr: Pointer; Action: TListNotification);
{:
procedure Notify overrides inherited Notify calls inherited Notify.
Also calls the dataowners Notify, if the lis is mirror  list
}
begin
  inherited Notify(Ptr, Action);
  if not IsDataOwner then
    DataOwner.Notify(Ptr, Action);
end;

procedure TgaSharedDoubleList.NotifyNodeChange(ANode: PdllNode; Action: 
        TgaNodeNotification);
{:
procedure NotifyNodeChange overrides inherited NotifyNodeChange.
If list IsDataOwner, the calls inherited NotifyNodeChange, otherwise calls
DataOwners NotifyNodeChange
}
begin
  if IsDataOwner then
    inherited NotifyNodeChange(ANode, Action)
  else
    DataOwner.NotifyNodeChange(ANode, Action);
end;

procedure TgaSharedDoubleList.RemoveDataUser(ADataUser: TgaListBaseObject);
{:
procedure RemoveDataUser overrides inherited RemoveDataUser.
Calls inherited RemoveDataUser if the list is data owner, otherwise
raises an exception.
}
begin
  inherited RemoveDataUser(ADataUser);
  if (not IsDataOwner) and (DataOwner <> nil) then
    DataOwner.RemoveDataUser(ADataUser);
end;

procedure TgaSharedDoubleList.RemoveNodeChangeListener(ANode: PdllNode; 
        AListener: TgaListBaseObject);
begin
  if IsDataOwner then
    inherited RemoveNodeChangeListener(ANode, AListener)
  else
    DataOwner.RemoveNodeChangeListener(ANode, AListener);
end;

procedure TgaSharedDoubleList.SetEndPos(APositionedList: TgaDoubleList; 
        AStrictEndPos: Boolean);
{:
procedure SetEndPos - Sets the lits's last item to be the current item of the
APostionedList. If StrictEnPos is true, the items inserted to the DataOwnerList
between the last item and the item after that, are not accompanied to this list.
If StrictEnPos is False, all items added before the item next to the last item
set are absorbed into the list.
If the PostionedList is at Eof, then StrictEndPos do not have any effect.
APositionedList can be self.
}
begin
  if IsDataOwner then
    raise EgaLinkListError.CreateFmt(SListIsNotAMirroringList, [SCantSetTheStartOrEndPostions]);
  if (DataOwner <> APositionedList) and
    ((APositionedList is TgaSharedDoubleList) and
      (DataOwner <> (APositionedList as TgaSharedDoubleList).DataOwner)) then
    raise EgaLinkListError.CreateFmt(SListsDoNotShareData, [SCantSetTheStartOrEndPostions]);
  if APositionedList.Eof then
    SetTailNode(APositionedList.Cursor)
  else
    SetTailNode(APositionedList.Cursor.dllnNext);
  if not IsCursorCorrect then
    FCursorObj.Reset;
  FStrictEndPos := AStrictEndPos;
  Assert(IsList(Head, Tail));
end;

procedure TgaSharedDoubleList.SetHeadNode(ANode: PdllNode);
begin
  if ANode = Head then
    Exit;
  if IsDataOwner then
    inherited SetHeadNode(ANode)
  else begin
    Assert(DataOwner <> nil);
    DataOwner.RemoveNodeChangeListener(Head, Self);
    FHead := ANode;
    DataOwner.AddNodeChangeListener(Head, Self, npFirstPass);
  end;
end;

procedure TgaSharedDoubleList.SetStartPos(APositionedList: TgaDoubleList; 
        AStrictStartPos: boolean);
{:
procedure SetStartPos - Sets the lits's first item to be the current item of the
APostionedList. If StrictStartPos is true, the items inserted to the
DataOwnerList between the first item and the item before that, are not
accompanied to this list. If StrictEnPos is False, all items added after the
item previous to the last item set are absorbed into the list.
If the PostionedList is at Bof, then StrictStartPos do not have any effect.
APositionedList can be self.
}
begin
  if IsDataOwner then
    raise EgaLinkListError.CreateFmt(SListIsNotAMirroringList, [SCantSetTheStartOrEndPostions]);
  if (DataOwner <> APositionedList) and
    ((APositionedList is TgaSharedDoubleList) and
      (DataOwner <> (APositionedList as TgaSharedDoubleList).DataOwner)) then
    raise EgaLinkListError.CreateFmt(SListsDoNotShareData, [SCantSetTheStartOrEndPostions]);
  if APositionedList.Bof then
    SetHeadNode(APositionedList.Cursor)
  else
    SetHeadNode(APositionedList.Cursor^.dllnPrev);
  if not IsList(Head, Tail) then
    SetEndPos(APositionedList, StrictEndPos);
  if not IsCursorCorrect then
    FCursorObj.Reset;
  FStrictStartPos := AStrictStartPos;
  Assert(IsList(Head, Tail));
end;

procedure TgaSharedDoubleList.SetTailNode(ANode: PdllNode);
begin
  if ANode = Tail then
    Exit;
  if IsDataOwner then
    inherited SetTailNode(ANode)
  else begin
    Assert(DataOwner <> nil);
    DataOwner.RemoveNodeChangeListener(Tail, Self);
    FTail := ANode;
    DataOwner.AddNodeChangeListener(Tail, Self, npFirstPass);
  end;
end;

{
**************************** TgaDoubleListBookmark *****************************
}
constructor TgaDoubleListBookmark.Create(AOwnerList: TgaSimpleDoubleList; 
        ANode: PdllNode);
{:
Constructor Create overrides the inherited Create.
First inherited Create is called, then the internal data structure is
initialized to store tha list for which a bookmark was created and current
postion inside this list.
}
begin
  inherited Create;
  FOwnerList := AOwnerList;
  FOwnerList.AddDataUser(Self, npSecondPass);
  SetCursor(ANode);
  FisValid := FCursor <> nil;
end;

destructor TgaDoubleListBookmark.Destroy;
{:
GetItem is the read access method of the Item property.
It retrives the value of the item represented by the cursor. The method has
to be overridden by the descendant classes.
}
begin
  SetCursor(nil);
  if OwnerList <> nil then
    OwnerList.RemoveDataUser(Self);
  inherited;
end;

function TgaDoubleListBookmark.BOF: Boolean;
begin
  Assert(IsValid);
  Result := Cursor = OwnerList.Head;
end;

procedure TgaDoubleListBookmark.DataOwnerDestroyed;
begin
  SetCursor(nil);
  FIsValid := False;
  OwnerList.RemoveDataUser(Self);
  FOwnerList := nil;
end;

function TgaDoubleListBookmark.EOF: Boolean;
begin
  Assert(IsValid);
  Result := Cursor = OwnerList.Tail;
end;

procedure TgaDoubleListBookmark.First;
begin
  Assert(IsValid);
  SetCursor(OwnerList.Head.dllnNext);
end;

function TgaDoubleListBookmark.GetIsValid: Boolean;
{:
function GetIsValid overrides inherited GetIsValid.
Returns: True, if the Bookmark is valid
False, if it is not.
}
begin
  Result := FIsValid;// and (OwnerList <> nil) and OwnerList.IsNodeInside(FCursor__);
end;

function TgaDoubleListBookmark.GetItem: Pointer;
{:
function GetItem overrides inherited GetItem.
Returns: A pointer to the item represented by the Bookmark
}
begin
  if not IsValid then
    raise EgaListBookmarkError.CreateFmt(SInvalidBookmark, [SCantGetItem]);
  Result := Cursor.dllnData;
end;

function TgaDoubleListBookmark.IsValidFor(AList: TgaSimpleDoubleList): Boolean;
{:
function IsValidFor checks if the bookmark is valid for a list represented by
the AList.
Returns: True, if the AList uses the same data as bookmarks owner list
(AList = OwnerList or AList.DataOwner = OwnerList.DataOwner, if this compare
is (partially) applicable), and the node represented by the bookmark's cursor is
inside the AList
}
begin
  Assert(OwnerList <> nil);
  // use IsValid if possible as IsValid is more optimized
  if AList = OwnerList then
    Result := IsValid
  else begin
    if (AList is TgaSharedDoubleList) and (OwnerList is TgaSharedDoubleList) then
      Result := TgaSharedDoubleList(OwnerList).DataOwner = TgaSharedDoubleList(AList).DataOwner
    else if AList is TgaSharedDoubleList then
      Result := OwnerList = TgaSharedDoubleList(AList).DataOwner
    else if OwnerList is TgaSharedDoubleList then
      Result := TgaSharedDoubleList(OwnerList).DataOwner = AList
    else
      Result := False;
    if not Result then
      Exit;
    Result := AList.IsNodeInside(Cursor);
  end;
end;

procedure TgaDoubleListBookmark.Last;
begin
  Assert(IsValid);
  SetCursor(OwnerList.Tail.dllnPrev);
end;

procedure TgaDoubleListBookmark.Next;
begin
  Assert(IsValid);
  if not Eof then
    SetCursor(Cursor.dllnNext);
end;

procedure TgaDoubleListBookmark.NodeInfoChange(ANode: PdllNode; Action: 
        TgaNodeNotification; AffectedNode: TgaAfftectedNode);
begin
  inherited;
  case Action of
    nnDeleted:
      if (AffectedNode = anThisNode) and (ANode = Cursor) then
      begin
        if Eof then
          Previous
        else
          Next;
      end;
    nnCleared:
      Reset;
  end;
end;

procedure TgaDoubleListBookmark.Previous;
begin
  Assert(IsValid);
  if not Bof then
    SetCursor(Cursor.dllnPrev);
end;

procedure TgaDoubleListBookmark.Reset;
begin
  SetCursor(OwnerList.Head);
  Assert(IsValid);
end;

procedure TgaDoubleListBookmark.SetCursor(ACursor: PdllNode);
begin
  Assert(Self <> nil);
  if ACursor <> FCursor then
  begin
    Assert((OwnerList <> nil));
    if (ACursor <> nil) and (not OwnerList.IsNodeInside(ACursor)) then
      raise EgaLinkListError.Create(SInvalidCursor);
    OwnerList.RemoveNodeChangeListener(FCursor, Self);
    FCursor := ACursor;
    OwnerList.AddNodeChangeListener(FCursor, Self, npSecondPass);
  end;
end;

procedure TgaDoubleListBookmark.SetItem(Value: Pointer);
{:
procedure SetItem overrides inherited SetItem.
Changes the item represented by the bookmark to the new Value.
}
begin
  if not IsValid then
    raise EgaListBookmarkError.CreateFmt(SInvalidBookmark, [SCantSetItem]);
  OwnerList.SetNodeData(Cursor, Value);
end;

procedure TgaDoubleListBookmark.Syncronize(ABookmark: TgaDoubleListBookmark);
begin
  Assert(IsValid);
  Assert(ABookmark <> nil);
  if not ABookmark.IsValidFor(OwnerList) then
    raise EgaLinkListError.Create(SInvalidBookmark);
  SetCursor(ABookMark.Cursor);
end;

{
****************************** TgaListBaseObject *******************************
}
procedure TgaListBaseObject.DataOwnerDestroyed;
begin
  ; // Do nothing here
end;

procedure TgaListBaseObject.NodeInfoChange(ANode: PdllNode; Action: 
        TgaNodeNotification; AffectedNode: TgaAfftectedNode);
begin
  ; // Do nothing here
end;

{:
GetIsValid is the read access method of the IsValid property.
Descendant classes should override this method to give appropriate result
}
{:
GetItem is the read access method of the Item property.
It retrives the value of the item represented by the cursor. The method has 
to be overridden by the descendant classes.
}
{:
SetItem is the write access method of the Item property.
It changes the value of the item represented by the cursor. The method has 
to be overridden by the descendant classes.
}

end.

