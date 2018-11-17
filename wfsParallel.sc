FaustWfsParallel : MultiOutUGen
{
  *ar { | in1, speed(30.0), start(0.0), time(15.0), x_offset(0.0), y(1.0) |
      ^this.multiNew('audio', in1, speed, start, time, x_offset, y)
  }

  *kr { | in1, speed(30.0), start(0.0), time(15.0), x_offset(0.0), y(1.0) |
      ^this.multiNew('control', in1, speed, start, time, x_offset, y)
  } 

  checkInputs {
    if (rate == 'audio', {
      1.do({|i|
        if (inputs.at(i).rate != 'audio', {
          ^(" input at index " + i + "(" + inputs.at(i) + 
            ") is not audio rate");
        });
      });
    });
    ^this.checkValidInputs
  }

  init { | ... theInputs |
      inputs = theInputs
      ^this.initOutputs(25, rate)
  }

  name { ^"FaustWfsParallel" }


  info { ^"Generated with Faust" }
}

