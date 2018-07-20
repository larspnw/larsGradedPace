using Toybox.WatchUi as Ui;
using Toybox.Test as Test;

class larsGradedPaceView extends Ui.SimpleDataField {

	//TODO - how do you calc lap data?
	//TODO - how many samples should we have?

	const METERS_TO_MILES = 0.000621371;
    
    const samples = 5;
	var altitudes = new[samples];
	var distances = new [samples];
	var speeds = new [samples];

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "GAP 5s";
        
        for (var i = 0; i < samples; i++) {
        	altitudes[i] = 0.0; 
        	distances[i] = 0.0;
        	speeds[i] = 0.0;
        }
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
        
        if ( info.timerState != 3 ) {
        	System.println("Timer not running");
        	return;
        }
        
        //store altitude and distance for a number of samples
    	for (var i = samples - 2; i >= 0 ; i--) {
    		//System.println("i: " + i);
    		if ( altitudes[i] != null && distances[i] != null && speeds[i] != null) {
    			altitudes[i+1] = altitudes[i];
    			distances[i+1] = distances[i];
    			speeds[i+1] = speeds[i];
    		}
    	}
    	
    	altitudes[0] = info.altitude;
    	distances[0] = info.elapsedDistance;
    	speeds[0] = info.currentSpeed;
    	//testing - distances[0] = Time.now().value();
    	
    	var grade = calcGrade();
    	
    	var gap = calcGap(getAverage(speeds), grade);
    	
        return gap;
    }
  
  	
    function getAverage(a) {
        var count = 0;
        var sum = 0.0;
        for (var i = 0; i < a.size(); ++i) {
            if (a[i] > 0.0) {
                count++;
                sum += a[i];
            }
        }
        if (count > 0) {
            return sum / count;
        } else {
            return null;
        }
    }
     
    function calcGrade() {
    
    	var altDelta = 0;
    	var distDelta = 0;
    	var delta = 0;
    	var count = 0;
    	
    	//use buffer data to determine rolling grade
    	for (var i = 0; i < samples -2; i++ ) {
    		if ( altitudes[i] != null && altitudes[i+1] != null 
    				&& distances[i] != null && distances[i+1] != null ) {
    			
    			delta = (altitudes[i] - altitudes[i+1]);
    			//System.println("alt delta: " + delta);
    			altDelta += delta;
    		
    			delta = (distances[i] - distances[i+1]);
    			//System.println("dist delta: " + delta);
    			distDelta += delta;
    			count++;
    		}
    		
    	}
    	
    	//System.println("aggregates alt-dist: " + altDelta + " - " + distDelta);
    	
    	if ( count == 0 ) {
    		return 0;
    	}
    	
    	// calc avgs then units
    	var altAvg = (altDelta/count) * METERS_TO_MILES;
    	var distAvg = (distDelta/count) * METERS_TO_MILES;
    	
    	//System.println("avg: " + altAvg + " - " + distAvg);
    	
    	if ( distAvg == 0 ) {
    		System.println("distance delta average is 0 - strange");
    		return 0;
    	}
    	var grade = altAvg/distAvg * 100;
    	//sanity check
    	if ( grade < -45 || grade > 45 ) {
    		System.println("strange grade calc, adjusting: " + grade);
    		return 0;
    	}
    	//System.println("grade%: " + grade);
    	return grade;
    	
    }

	function calcGap(speed, grade) {
		/*
		From: https://www.runnersworld.com/advanced/a20820206/downhill-all-the-way/
		Going Up
		Every 1% upgrade slows your pace 3.3% (1/30th)
		Every 100 feet of elevation gain slows you 6.6% of your average one mile pace (2% grade/mile).
		Example: A race that climbs 300 feet would slow an 8-minute miler (3 x .066 x 8 x 60 seconds) = 94 seconds slower at the finish
		
		Going Down
		Every 1% downgrade speeds your pace 55% of 3.3% = 1.8%
		Every 100 feet of elevation descent speeds you 3.6% of your average one mile pace (2% grade/mile).
		Example: A race that descends 300 feet would speed an 8-minute miler (3 x .036 x 8 x 60 seconds) = 55 seconds faster at the finish
		*/

		//calc speed in min per mile - comes in meters per second
		//meters per hour = speed * 60 * 60
		//miles per hour = speed * 60 * 60 * METERS_TO_MILES
		//min per mile = 60 / miles per hour
		
		if ( speed == null ) {
			return;
		}
		
		var empspeed = 60 / (speed * 60 * 60 * METERS_TO_MILES);
		
		//	apply study metics to current pace
		var paceCalc = 0;
		
		if ( grade > 0 ) {
			//uphill case
			//cost is 3.3% of pace for every 1% of grade
			paceCalc = empspeed - (empspeed * ((grade * 3.3)/100) );
		} else {
			//downhill case
			paceCalc = empspeed + (empspeed * ((grade * -1 * 1.8)/100) );
		}
		
		//System.println("speed/grade/gap: " + empspeed + " / " + grade + " / " + paceCalc);
		
		//format for min and sec
		return formatPace(paceCalc);
	}
	
	function formatPace(pace) {
		var sPace = "" + pace;
		
		var index = sPace.find(".");
		var min = sPace.substring(0,index);
		var dSec = sPace.substring(index+1, index+3);
		//System.println("dSec: " + dSec);
		var sec = dSec.toNumber() * 60;
		
		var sSec = "" + sec;
		if (sSec.length() > 2) {
			sSec = sSec.substring(0, 2);
		}
		
		var formatted;
		if ( sec < 10) {
			formatted = min + ":0" + sSec;
		} else {
			formatted = min + ":" + sSec;
		}
		
		//System.println("formatted/expected: " + formatted + " / " + expected);

		//return true;
		return formatted;
	}
	
}

class testFormatPace {

	(:test)
	function testFormatPace1(logger) {
		
		var pace = 9.99;
		var expected = "9:59";
		//Test.assertEqual(formatPace(10.0), "10:00");
		//Test.assertEqual(formatPace(8.4), "8:24");
		//Test.assertEqual(formatPace(9.69), "9:41");
		//Test.assertEqual(formatPace(9.99), "9:59");
	
		var sPace = "" + pace;
		
		var index = sPace.find(".");
		var min = sPace.substring(0,index);
		var dSec = sPace.substring(index+1, index+3);
		System.println("dSec: " + dSec);
		var sec = dSec.toNumber() * 60;
		
		var sSec = "" + sec;
		if (sSec.length() > 2) {
			sSec = sSec.substring(0, 2);
		}
		
		var formatted;
		if ( sec < 10) {
			formatted = min + ":0" + sSec;
		} else {
			formatted = min + ":" + sSec;
		}
		
		System.println("formatted/expected: " + formatted + " / " + expected);
	
		
		
		return true;
	}
	
	
}