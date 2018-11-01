program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  zabbix_sender in '..\..\Include\zabbix_sender.pas';

var
  lArgZ             : string;
  lArgP             : string;
  lArgS             : string;
  lArgK             : string;
  lArgO             : string;

  lZabbixValue      : TZabbix_sender_value;
  lResponse         : MarshaledAString;
  lRetCode          : integer;

  lMarshaller       : TMarshaller;
begin
  System.ReportMemoryLeaksOnShutdown := True;

  try
    // z - host Zabbix server (or IP address)
    // p - port Zabbix server
    // s - host name (set in Zabbix web interface)
    // k - date item Key
    // o - sent values
    if not FindCmdLineSwitch('z', lArgZ, True) then
    begin
      writeln(format('Usage: %s -z [ZABBIX SERVER] -p [ZABBIX PORT] -s [HOST NAME] -k [ITEM KEY] -o [SENT VALUES]', [System.IOUtils.TPath.GetFileName(ParamStr(0))]));
      exit;
    end;

    lArgP := '10051';
    FindCmdLineSwitch('p', lArgP, True);

    if not FindCmdLineSwitch('s', lArgS, True) then
    begin
      writeln(format('Usage: %s -z [ZABBIX SERVER] -p [ZABBIX PORT] -s [HOST NAME] -k [ITEM KEY] -o [SENT VALUES]', [System.IOUtils.TPath.GetFileName(ParamStr(0))]));
      exit;
    end else
      lZabbixValue.host := lMarshaller.AsAnsi(lArgS, CP_UTF8).ToPointer;  // MarshaledAString(UTF8String(lArgS));

    if not FindCmdLineSwitch('k', lArgK, True) then
    begin
      writeln(format('Usage: %s -z [ZABBIX SERVER] -p [ZABBIX PORT] -s [HOST NAME] -k [ITEM KEY] -o [SENT VALUES]', [System.IOUtils.TPath.GetFileName(ParamStr(0))]));
      exit;
    end else
      lZabbixValue.key := lMarshaller.AsAnsi(lArgK, CP_UTF8).ToPointer; //MarshaledAString(UTF8String(lArgK));

    if not FindCmdLineSwitch('o', lArgO, True) then
    begin
      writeln(format('Usage: %s -z [ZABBIX SERVER] -p [ZABBIX PORT] -s [HOST NAME] -k [ITEM KEY] -o [SENT VALUES]', [System.IOUtils.TPath.GetFileName(ParamStr(0))]));
      exit;
    end else
      lZabbixValue.value := lMarshaller.AsAnsi(lArgO, CP_UTF8).ToPointer; //  MarshaledAString(UTF8String(lArgO));

    lRetCode := zabbix_sender_send_values(lMarshaller.AsAnsi(lArgZ, CP_UTF8).ToPointer, StrToIntDef(lArgP, 10051), nil, @lZabbixValue, 1, lResponse);
    try
      writeln(Format('lRetCode= %d', [lRetCode]));
      writeln(Format('lResponse= %s', [lResponse]));
    finally
      zabbix_sender_free_result(lResponse);
    end;

    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;


  WriteLn;
  Write('Press Enter to exit...');
  Readln;

end.
