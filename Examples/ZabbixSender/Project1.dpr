program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  ZabbixSender in '..\..\Include\ZabbixSender.pas';

var
  lArgZ             : string;
  lArgP             : string;
  lArgS             : string;
  lArgK             : string;
  lArgO             : string;

  lZabbixSender     : TZabbixSender;
  lJSONObject       : TJSONObject;
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
    end;
    if not FindCmdLineSwitch('k', lArgK, True) then
    begin
      writeln(format('Usage: %s -z [ZABBIX SERVER] -p [ZABBIX PORT] -s [] -k [] -o []', [System.IOUtils.TPath.GetFileName(ParamStr(0))]));
      exit;
    end;

    if not FindCmdLineSwitch('o', lArgO, True) then
    begin
      writeln(format('Usage: %s -z [ZABBIX SERVER] -p [ZABBIX PORT] -s [] -k [] -o []', [System.IOUtils.TPath.GetFileName(ParamStr(0))]));
      exit;
    end;

    lZabbixSender := TZabbixSender.Create(lArgZ, StrToIntDef(lArgP, 10051));
    try
      // Send metrics to zabbix trapper
      lZabbixSender.Add(TZabbixMetric.Create(lArgS, lArgK, lArgO));
      lJSONObject := lZabbixSender.Send;
      try
        writeln(Format('response: %s', [lJSONObject.ToJSON]));
      finally
        FreeAndNil(lJSONObject);
      end;
    finally
      FreeAndNil(lZabbixSender);
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
