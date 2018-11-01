unit ZabbixSender;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.JSON,
  System.Generics.Collections,
  IdGlobal,
  IdIOHandler,
  IdTCPClient;


type
  TZabbixMetric = record
  private
    Host   : string;
    Key    : string;
    Value  : string;
    Clock  : Int64;
  public
    class function Create(const AHost: string; const AKey: string; const AValue: string; ATimeStamp: Boolean = true): TZabbixMetric; overload; static;
    class function Create(const AHost: string; const AKey: string; const AValue: Integer; ATimeStamp: Boolean = true): TZabbixMetric; overload; static;
    class function Create(const AHost: string; const AKey: string; const AValue: Double; ATimeStamp: Boolean = true): TZabbixMetric; overload; static;
    class function Create(const AHost: string; const AKey: string; const AValue: Boolean; ATimeStamp: Boolean = true): TZabbixMetric; overload; static;
  end;

type
  TZabbixSender = class( TList<TZabbixMetric>)
  private
    FServer : string;
    FPort   : Word;
    function Write(const ZabbixData: string): TBytes;
  public
    constructor Create(const AServer: string; APort: word = 10051); overload;
    destructor Destroy; override;
    function Send(): TJSONObject;
  end;


implementation

function SwapInt64(Value: Int64): Int64;
var
  P: PInteger;
begin
  Result := (Value shl 32) or (Value shr 32);
  P := @Result;
  P^ := (Swap(P^) shl 16) or (Swap(P^ shr 16));
  Inc(P);
  P^ := (Swap(P^) shl 16) or (Swap(P^ shr 16));
end;

class function TZabbixMetric.Create(const AHost: string; const AKey: string; const AValue: string; ATimeStamp: Boolean = true): TZabbixMetric;
begin
  result.Host := AHost;
  result.Key := AKey;
  result.Value := AValue;
  result.Clock := 0;
  if ATimeStamp then
    result.Clock := System.DateUtils.DateTimeToUnix(Now, false);
end;

class function TZabbixMetric.Create(const AHost: string; const AKey: string; const AValue: Integer; ATimeStamp: Boolean = true): TZabbixMetric;
begin
  result.Host := AHost;
  result.Key := AKey;
  result.Value := IntToStr(AValue);
  result.Clock := 0;
  if ATimeStamp then
    result.Clock := System.DateUtils.DateTimeToUnix(Now, false);
end;

class function TZabbixMetric.Create(const AHost: string; const AKey: string; const AValue: Double; ATimeStamp: Boolean = true): TZabbixMetric;
begin
  result.Host := AHost;
  result.Key := AKey;
  result.Value := FloatToStr(AValue);
  result.Clock := 0;
  if ATimeStamp then
    result.Clock := System.DateUtils.DateTimeToUnix(Now, false);
end;

class function TZabbixMetric.Create(const AHost: string; const AKey: string; const AValue: Boolean; ATimeStamp: Boolean = true): TZabbixMetric;
begin
  result.Host := AHost;
  result.Key := AKey;
  result.Value := BoolToStr(AValue);
  result.Clock := 0;
  if ATimeStamp then
    result.Clock := System.DateUtils.DateTimeToUnix(Now, false);
end;

//
constructor TZabbixSender.Create(const AServer: string; APort: word = 10051);
begin
  inherited Create;
  Self.FServer := AServer;
  Self.FPort := APort;
end;

destructor TZabbixSender.Destroy;
begin
  inherited Destroy;
end;

(*
 * Header and data length
 * Overview
 * Header and data length are present in response and request messages between Zabbix components. It is required to determine the length of message.
 *
 * <HEADER> - "ZBXD\x01" (5 bytes)
 * <DATALEN> - data length (8 bytes). 1 will be formatted as 01/00/00/00/00/00/00/00 (eight bytes, 64 bit number in little-endian format)
 * To not exhaust memory (potentially) Zabbix protocol is limited to accept only 128MB in one connection.
**)
 function TZabbixSender.write(const ZabbixData: string): TBytes;
var
  lTcpClient  : TIdTcpClient;
  lBuffer     : TIdBytes;

  lHeader     : string;
  lSize       : Int64;
begin
  lTcpClient := TIdTcpClient.Create(nil);
  try
    lTcpClient.Host := Self.FServer;
    lTcpClient.Port := Self.FPort;
    lTcpClient.ReadTimeout := 1000;
    lTcpClient.Connect;
    if not lTcpClient.Connected then
      raise Exception.Create('Client not connected to carbon server');

    lTcpClient.IOHandler.WriteBufferOpen;
    try
      lTcpClient.IOHandler.Write('ZBXD' + #01, IndyTextEncoding(TEncoding.ASCII));
      lTcpClient.IOHandler.Write(SwapInt64(Int64(Length(ZabbixData))));
      lTcpClient.IOHandler.Write(ZabbixData, IndyTextEncoding(TEncoding.ASCII));
      lTcpClient.IOHandler.WriteBufferFlush;
    finally
      lTcpClient.IOHandler.WriteBufferClose;
    end;

    lHeader := LTcpClient.IOHandler.WaitFor('ZBXD'+#01, true, true, IndyTextEncoding(TEncoding.ASCII), 5000);
    lSize:= SwapInt64(LTcpClient.IOHandler.ReadInt64());
    repeat
      AppendByte(lBuffer, LTcpClient.IOHandler.ReadByte);
    until lTcpClient.IOHandler.InputBufferIsEmpty;

    result := TEncoding.UTF8.Convert(TEncoding.ASCII, TEncoding.UTF8, TBytes(lBuffer));
  finally
    FreeAndNil(lTcpClient);
  end;
end;


(*
 * Overview
 * Zabbix sender request
 * Zabbix server response
 * Alternatively Zabbix sender can send request with a timestamp
 * Zabbix server response
 * 4 Trapper items
 * Overview
 * Zabbix server uses a JSON- based communication protocol for receiving data from Zabbix sender with the help of trapper item.
 *
 * For definition of header and data length please refer to protocol details section.
 *
 * Zabbix sender request
 * {
 *     "request":"sender data",
 *     "data":[
 *         {
 *             "host":"<hostname>",
 *             "key":"trap",
 *             "value":"test value"
 *         }
 *     ]
 * }
 * Zabbix server response
 * {
 *     "response":"success",
 *     "info":"processed: 1; failed: 0; total: 1; seconds spent: 0.060753"
 * }
 * Alternatively Zabbix sender can send request with a timestamp
 * {
 *     "request":"sender data",
 *     "data":[
 *         {
 *             "host":"<hostname>",
 *             "key":"trap",
 *             "value":"test value",
 *             "clock":1516710794
 *         },
 *         {
 *             "host":"<hostname>",
 *             "key":"trap",
 *             "value":"test value",
 *             "clock":1516710795
 *         }
 *     ],
 *     "clock":1516712029,
 *     "ns":873386094
 * }
 * Zabbix server response
 * {
 *     "response":"success",
 *     "info":"processed: 2; failed: 0; total: 2; seconds spent: 0.060904"
 * }
**)
function TZabbixSender.Send(): TJSONObject;
var
  i             : Integer;
  lRequestObj   : TJSONObject;
  lDataArr      : TJSONArray;
  lDataItem     : TJSONObject;
  lResponseObj  : TJSONObject;
begin
  lRequestObj := TJSONObject.Create;
  try
    lRequestObj.AddPair(TJSONPair.Create('request', TJSONString.Create('sender data')));
    lDataArr := TJSONArray.Create;
    try
      for I := 0 to Self.Count - 1 do
      begin
        lDataItem := TJSONObject.Create;
        try
          lDataItem.AddPair(TJSONPair.Create('host', TJSONString.Create(Self.Items[i].Host)));
          lDataItem.AddPair(TJSONPair.Create('key', TJSONString.Create(Self.Items[i].Key)));
          lDataItem.AddPair(TJSONPair.Create('value', TJSONString.Create(Self.Items[i].Value)));
          lDataItem.AddPair(TJSONPair.Create('clock', TJSONNumber.Create(Self.Items[i].Clock)));
        finally
          lDataArr.AddElement(lDataItem);
        end;
      end;
    finally
      lRequestObj.AddPair(TJSONPair.Create('data', lDataArr));
    end;
    lRequestObj.AddPair(TJSONPair.Create('clock', TJSONNumber.Create(System.DateUtils.DateTimeToUnix(Now, false))));

    lResponseObj := TJSONObject.Create;
    try
      try
        lResponseObj.Parse(Self.Write(lRequestObj.ToJSON), 0, true);
        Self.Clear;
      except
        on E:Exception do
          lResponseObj.AddPair(TJSONPair.Create('exception', TJSONString.Create(E.Message)));
      end;
      result := lResponseObj.Clone as TJSONObject;
    finally
      FreeAndNil(lResponseObj);
    end;

  finally
    FreeAndNil(lRequestObj)
  end;
end;


end.
