using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.UserProfile as User;

class SnapshotHRView extends Ui.DataField {

	var heartRate;
	var heartRateLabel;
	var heartRateZones;
	
	var firstField;
	var firstFieldMode;
	var secondField;
	var secondFieldMode;
	var bottomField;
	var bottomFieldMode;

	var invertMiddleBackground;
	var foregroundColour;
	var backgroundColour;
	var lineColour;

	var arrayColours = new [5];
    var arrayHRValue = new [189];
    var arrayHRZone = new [189];
	var curPos;
	var aveHRValue;
	var aveHRCount;
	var HRmin;
	var HRmax;
	var HRmid;
	

	function initialize() {

 		DataField.initialize();

		var usePreferences = 1;
		
		var background = 1;  // 0=white; 1=black
		invertMiddleBackground = true;  // ... of the graph only
		firstFieldMode = 2;  // 0=time-of-day, 1=battery, 2=aveHR, 3=CAD, 4=aveCAD ... -1=none
		secondFieldMode = 0;
		bottomFieldMode = 0;
		
		heartRateZones = User.getHeartRateZones(User.getCurrentSport());
//		heartRateZones = [98, 127, 146, 166, 185, 195];

		HRmid = ( heartRateZones[1] + (heartRateZones[5]-heartRateZones[1])*0.5 ).toNumber();

		if (usePreferences == 1) {
			background = Application.getApp().getProperty("blackBackground");
			invertMiddleBackground = Application.getApp().getProperty("invertMiddleBackground");
			firstFieldMode = Application.getApp().getProperty("firstFieldMode");
			secondFieldMode = Application.getApp().getProperty("secondFieldMode");
			bottomFieldMode = Application.getApp().getProperty("bottomFieldMode");
		}

		if (background == 1) {
			foregroundColour = Gfx.COLOR_WHITE;
			backgroundColour = Gfx.COLOR_BLACK;
			lineColour = Gfx.COLOR_DK_GRAY;
		} else {
			foregroundColour = Gfx.COLOR_BLACK;
			backgroundColour = Gfx.COLOR_WHITE;
			lineColour = Gfx.COLOR_LT_GRAY;
		}

        for (var i = 0; i < arrayHRValue.size(); ++i) {
            arrayHRValue[i] = 0;
            arrayHRZone[i] = -1;
        }

        curPos = 0;
        aveHRValue = 0;
        aveHRCount = 0;
        arrayColours = [Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLUE, Gfx.COLOR_DK_GREEN, Gfx.COLOR_ORANGE, Gfx.COLOR_DK_RED];

	}


	function onLayout(dc) {
	}

	function onShow() {
	}

	function onHide() {
	}


	function onUpdate(dc) {

		dc.setColor(foregroundColour, backgroundColour);
		dc.clear();
		dc.setColor(foregroundColour, Gfx.COLOR_TRANSPARENT);

		textC(dc, 108, 6, Gfx.FONT_XTINY,  heartRateLabel);
		textC(dc, 106, 33, Gfx.FONT_NUMBER_HOT, heartRate);

		if (firstFieldMode >= 0) {
			textL(dc, 13, 46, Gfx.FONT_LARGE, firstField);
		}
		
		if (secondFieldMode >= 0) {
			textR(dc, 201, 46, Gfx.FONT_LARGE, secondField);
		}

		textC(dc, 107.5, 160, Gfx.FONT_NUMBER_MEDIUM, bottomField);

		if (invertMiddleBackground == true) {
			// invert the colours of the middle two fields
			dc.setColor(foregroundColour, foregroundColour);	
			dc.fillRectangle(0, 58, 215, 85);
			dc.setColor(backgroundColour, Gfx.COLOR_TRANSPARENT);	
		}

		// DRAW GRAPH

		var ii;
		var scaling;
		
        for (var i = 0; i < arrayHRValue.size(); ++i) {
        
        	ii = curPos-1-i;
        	if(ii < 0) {
        		ii = ii + arrayHRValue.size();
        	}
        	
        	if(arrayHRZone[ii] >=0) {
        	
				dc.setColor(arrayColours[arrayHRZone[ii]], Gfx.COLOR_TRANSPARENT);
				
				scaling = (arrayHRValue[ii] - HRmin).toFloat() / (HRmax - HRmin).toFloat();
				if(scaling > 1) {
					scaling = 1;
				} else if(scaling < 0) {
					scaling = 0;
				}
				
				dc.drawLine(201-i, 140, 201-i, (140-80*scaling).toNumber());
				
			}
			
        }

		// DRAW LINES

		if (invertMiddleBackground == true) {
			dc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_TRANSPARENT);
		} else {
			dc.setColor(lineColour, Gfx.COLOR_TRANSPARENT);
		}
		
		dc.drawLine(0, 58, 215, 58);
		dc.drawLine(0, 143, 215, 143);

		return true;
	}


	function compute(info) {
		
		heartRate = info.currentHeartRate;
		
		if (heartRate != null && heartRate >= heartRateZones[0] && info.elapsedTime != null && info.elapsedTime > 0) {

			aveHRValue = aveHRValue + heartRate;
			aveHRCount = aveHRCount + 1;
			
			if(aveHRCount > 3) {
			
				arrayHRValue[curPos] = (aveHRValue / aveHRCount).toNumber();	
			
				if (arrayHRValue[curPos] >= heartRateZones[0] && arrayHRValue[curPos] < heartRateZones[1]) {
					arrayHRZone[curPos] = 0;
				} else if (arrayHRValue[curPos] >= heartRateZones[1] && arrayHRValue[curPos] < heartRateZones[2]) {
					arrayHRZone[curPos] = 1;
				} else if (arrayHRValue[curPos] >= heartRateZones[2] && arrayHRValue[curPos] < heartRateZones[3]) {
					arrayHRZone[curPos] = 2;
				} else if (arrayHRValue[curPos] >= heartRateZones[3] && arrayHRValue[curPos] < heartRateZones[4]) {
					arrayHRZone[curPos] = 3;
				} else if (arrayHRValue[curPos] >= heartRateZones[4]) {
					arrayHRZone[curPos] = 4;
				}

				HRmin = HRmid + 5;
				HRmax = HRmid - 5;

        		for (var i = 0; i < arrayHRValue.size(); ++i) {
        			if(arrayHRZone[i] >=0) {
        	
        				if(arrayHRValue[i] > HRmax) {
        					HRmax = arrayHRValue[i];
        				} else if(arrayHRValue[i] < HRmin) {
        					HRmin = arrayHRValue[i];
        				}
        		
        			}        		
				}

				HRmin = HRmin - 10;
				if(HRmin < heartRateZones[0] + 5) { HRmin = heartRateZones[0] + 5; }  // set floor just above min HR

				HRmax = HRmax + 10;
				if(HRmax > heartRateZones[5] + 5) { HRmax = heartRateZones[5] + 5; }  // clip spikes just above max HR

//				Sys.println("" + curPos + " " + arrayHRValue[curPos] + " " + arrayHRZone[curPos] + " " + HRmin + " " + HRmax);

				curPos = curPos + 1;
				if(curPos > arrayHRValue.size()-1) {
					curPos = 0;
				}
				
				aveHRCount = 0;
				aveHRValue = 0;
				
			}
			
		}		

		if (heartRate == null || heartRate < heartRateZones[0]) {
			heartRateLabel = "Heart Rate";
		} else if (heartRate >= heartRateZones[0] && heartRate < heartRateZones[1]) {
			heartRateLabel = "WARM UP";
		} else if (heartRate >= heartRateZones[1] && heartRate < heartRateZones[2]) {
			heartRateLabel = "EASY";
		} else if (heartRate >= heartRateZones[2] && heartRate < heartRateZones[3]) {
			heartRateLabel = "AEROBIC";
		} else if (heartRate >= heartRateZones[3] && heartRate < heartRateZones[4]) {
			heartRateLabel = "THRESHOLD";
		} else if (heartRate >= heartRateZones[4]) {
			heartRateLabel = "MAXIMUM";
		}

		heartRate = toStr(heartRate);

		if (firstFieldMode >= 0) {
			if (firstFieldMode == 0) {
				firstField = fmtTime(Sys.getClockTime());
			} else if (firstFieldMode == 1) {
				firstField = toStr(Sys.getSystemStats().battery.toNumber()) + "%";
			} else if (firstFieldMode == 2) {
				firstField = toStr(info.averageHeartRate);
			} else if (firstFieldMode == 3) {
				firstField = toStr(info.currentCadence);
			} else {
				firstField = info.averageCadence;
				if (firstField != null) {
					firstField = firstField * 2;
				}
				firstField = toStr(firstField);
			}
		}

		if (secondFieldMode >= 0) {
			if (secondFieldMode == 0) {		
				secondField = fmtTime(Sys.getClockTime());
			} else if (secondFieldMode == 1) {
				secondField = toStr(Sys.getSystemStats().battery.toNumber()) + "%";
			} else if (secondFieldMode == 2) {		
				secondField = toStr(info.averageHeartRate);
			} else if (secondFieldMode == 3) {
				secondField = toStr(info.currentCadence);
			} else {
				secondField = info.averageCadence;
				if (secondField != null) {
					secondField = secondField * 2;
				}
				secondField = toStr(secondField);
			}
		}

		if (bottomFieldMode == 0) {
		
			var time;
			time = info.elapsedTime;
	
			if (time != null) {
				time /= 1000;
			} else {
				time = 0.0;
			}
	
			bottomField = fmtSecs(time);
		} else {
		
			bottomField = toDist(info.elapsedDistance);

		}

	}


	function toStr(o) {
		if (o != null && o > 0) {
			return "" + o;
		} else {
			return "---";
		}
	}


	function fmtTime(clock) {

		var h = clock.hour;

		if (!Sys.getDeviceSettings().is24Hour) {
			if (h > 12) {
				h -= 12;
			} else if (h == 0) {
				h += 12;
			}
		}

		return "" + h + ":" + clock.min.format("%02d");
	}


	function fmtSecs(secs) {

		if (secs == null) {
			return "---";
		}

		var s = secs.toLong();
		var hours = s / 3600;
		s -= hours * 3600;
		var minutes = s / 60;
		s -= minutes * 60;

		var fmt;
		if (hours > 0) {
			fmt = "" + hours + ":" + minutes.format("%02d") + ":" + s.format("%02d");
		} else {
			fmt = "" + minutes + ":" + s.format("%02d");
		}

		return fmt;
	}


	function toDist(dist) {
		if (dist == null) {
			return "0.00";
		}

		dist = dist / 1000;
		return dist.format("%.2f", dist);
	}


	function textL(dc, x, y, font, s) {
		if (s != null) {
			dc.drawText(x, y, font, s, Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
		}
	}

	function textR(dc, x, y, font, s) {
		if (s != null) {
			dc.drawText(x, y, font, s, Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
		}
	}

	function textC(dc, x, y, font, s) {
		if (s != null) {
			dc.drawText(x, y, font, s, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		}
	}

}
