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

  lZabbixValue        : TZabbix_sender_value;
  lResponse           : PAnsiChar;
  lRetCode            : integer;
begin
  System.ReportMemoryLeaksOnShutdown := True;

  try
    // z - хост Zabbix сервера (также можно использовать IP адрес)
    // p - порт Zabbix сервера
    // s - техническое имя наблюдаемого узла сети (указанное в веб-интерфейсе Zabbix)
    // k - ключ элемента данных
    // o - отправляемое значение
    if not FindCmdLineSwitch('z', lArgZ, True) then
    begin
      writeln(format('Usage: %s -z [ZABBIX SERVER] -p [ZABBIX PORT] -s [] -k [] -o []', [System.IOUtils.TPath.GetFileName(ParamStr(0))]));
      exit;
    end;

    lArgP := '10051';
    FindCmdLineSwitch('p', lArgP, True);

    if not FindCmdLineSwitch('s', lArgS, True) then
    begin
      writeln(format('Usage: %s -z [ZABBIX SERVER] -p [ZABBIX PORT] -s [] -k [] -o []', [System.IOUtils.TPath.GetFileName(ParamStr(0))]));
      exit;
    end else
      lZabbixValue.host := PAnsiChar(Ansistring(lArgS));

    if not FindCmdLineSwitch('k', lArgK, True) then
    begin
      writeln(format('Usage: %s -z [ZABBIX SERVER] -p [ZABBIX PORT] -s [] -k [] -o []', [System.IOUtils.TPath.GetFileName(ParamStr(0))]));
      exit;
    end else
      lZabbixValue.key := PAnsiChar(Ansistring(lArgK));

    if not FindCmdLineSwitch('o', lArgO, True) then
    begin
      writeln(format('Usage: %s -z [ZABBIX SERVER] -p [ZABBIX PORT] -s [] -k [] -o []', [System.IOUtils.TPath.GetFileName(ParamStr(0))]));
      exit;
    end else
      lZabbixValue.value :=  PAnsiChar(Ansistring(lArgO));

    lRetCode := zabbix_sender_send_values(PAnsiChar(AnsiString(lArgZ)), StrToIntDef(lArgP, 10051), nil, @lZabbixValue, 1, lResponse);
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
