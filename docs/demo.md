# SIH demo script

1. Start the edge API and dashboard.
2. Show the dashboard’s initial low-moisture irrigation advisory.
3. Send a high-water reading with PowerShell:

```powershell
Invoke-RestMethod http://localhost:3001/v1/readings -Method Post -ContentType 'application/json' -Body '{"waterLevelPct":82,"rainfallMm":32}'
```

4. Refresh the dashboard: it changes to a flood-risk warning.
5. Show the ESP32 serial payload and explain that the same JSON is posted over local Wi-Fi when available.
6. Show the farmer app as the offline, local-language-friendly action surface.
