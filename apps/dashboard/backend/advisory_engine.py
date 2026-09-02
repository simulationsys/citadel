def build_advisories(reading: dict, vision_result: dict = None) -> list:
    advisories = []
    
    soil_moisture = reading.get("soilMoisturePct", 0)
    temp = reading.get("temperatureC", 0)
    rainfall = reading.get("rainfallMm", 0)
    water_level = reading.get("waterLevelPct", 0)
    
    # 1. Irrigation rule
    if soil_moisture < 30 and rainfall < 2:
        advisories.append({
            "type": "irrigation",
            "severity": "warning",
            "title": "Irrigate now",
            "message": f"Low soil moisture detected ({soil_moisture:.1f}%). Irrigate this zone for 15 minutes.",
            "action": "START_IRRIGATION"
        })
        
    # 2. Heat-stress rule
    if temp >= 38 and soil_moisture < 40:
        advisories.append({
            "type": "heat",
            "severity": "warning",
            "title": "Heat-stress risk",
            "message": f"High temperature ({temp}°C) and dry soil. Irrigate during cooler evening hours.",
            "action": "SCHEDULE_EVENING_IRRIGATION"
        })
        
    # 3. Flood-risk rule
    if water_level >= 75 or rainfall >= 30:
        advisories.append({
            "type": "flood",
            "severity": "critical",
            "title": "Flood-risk alert",
            "message": f"High water level ({water_level:.1f}%) or heavy rainfall ({rainfall}mm). Inspect drainage channels immediately.",
            "action": "CHECK_DRAINAGE"
        })
        
    # 4. Vision ML Crop Health & Pest Risk integration
    if vision_result:
        label = vision_result.get("label", "").lower()
        confidence = vision_result.get("confidence", 0.0)
        crop = vision_result.get("crop", "crop")
        
        if "blight" in label or "fungal" in label or "spot" in label:
            advisories.append({
                "type": "disease",
                "severity": "critical" if confidence > 0.85 else "warning",
                "title": f"Crop Disease Risk ({label.replace('_', ' ').title()})",
                "message": f"AI vision detected {label.replace('_', ' ')} on {crop} with {confidence*100:.0f}% confidence. Prune infected leaves and check humidity.",
                "action": "INSPECT_CROP_LEAVES"
            })
        elif "pest" in label or "aphid" in label or "worm" in label:
            advisories.append({
                "type": "pest",
                "severity": "warning",
                "title": f"Pest Infestation Risk ({label.replace('_', ' ').title()})",
                "message": f"AI vision flagged possible pest activity ({label.replace('_', ' ')}) on {crop}. Deploy yellow sticky traps.",
                "action": "DEPLOY_PEST_TRAPS"
            })
            
    return advisories
