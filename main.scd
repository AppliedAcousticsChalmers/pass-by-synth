// #!"/Applications/SuperCollider/SuperCollider.app/Contents/MacOS/sclang"
// (
// QtGUI.palette = QPalette.light;
// )

// server options
(
Server.local.options.numOutputBusChannels = 25;
Server.local.options.numInputBusChannels = 0;
Server.internal.options.numOutputBusChannels = 25;
Server.internal.options.numInputBusChannels = 0;

Server.local.options.device ="Orion 32";// "UltraLite-mk4";

Server.local.options.blockSize = 128;
Server.internal.options.blockSize = 128;

// Archive.archiveDir = "~/scwork".standardizePath;
Server.local.options.memSize = 2.pow(16);
Server.internal.options.memSize = 2.pow(16);
s.boot;
);
// create WFS synth and OSC interface
(
(
// b = Buffer.read(s, "~/Downloads/truckTest.wav"); // remember to free the buffer later.

SynthDef(\passby, {
	arg t_trig, ampa=1, ampb=1, amp=1, gain=1, speed=0, tsim=10, y=1, x=0, fstCh=0, buffer1, buffer2;
	var in, in1, in2, pby, t, xt, cosphi, directivity;
	in1 = MulAdd(PlayBuf.ar(1, buffer1, BufRateScale.kr(buffer1), t_trig), ampa);
	in2 = MulAdd(PlayBuf.ar(1, buffer2, BufRateScale.kr(buffer2), t_trig), ampb);
	in = in1 + in2;
	t = Line.ar(0,tsim,dur: tsim, doneAction: 2);
	xt = speed*tsim/2 - speed*t + x;
	cosphi = abs(xt)/(y.pow(2) + xt.pow(2)).pow(0.5);
	directivity  = 10.pow((4*cosphi-2.5)/20);
	pby = FaustWfsParallel.ar(in, speed, t_trig, tsim, x, y);
	// pby = FaustWfsXY.ar(in1+in2, 0, y);
	Out.ar(fstCh, 10*amp*gain*pby)
	// Out.ar(fstCh, x)

	// Out.ar(fstCh, amp*gain*pby[0,1])
	// Out.ar(fstCh, amp*gain*(in1+in2))
}).add;
);

OSCdef(\trigPassby, {|msg ... args| Synth(\passby ,[
	t_trig: 1,
	ampa: 1,
	ampb: 1,
	amp:   1,
	gain: 1,
	speed: 50,
	tsim:  2,
	y: 0,
	x: 0,
	buffer1: a,
	buffer2: b,

])}, \pb)

);

// test the synthdef //////////////////////////////////////////////////
a = Buffer.readChannel(s, "/Users/gz/PhD/LabPrep/stationarySignals/lightProp_SSD154_G12_T30_RPM3000_V50.wav", channels:[0])
b = Buffer.readChannel(s, "/Users/gz/PhD/LabPrep/stationarySignals/lightRoll_SSD154_G12_T30_RPM3000_V50.wav", channels:[0])
(
Synth(\passby,  [
	\t_trig, 1,
	\ampa, 1,
	\ampb, 1,
	\amp,   1,
	\gain, 1,
	\speed, 50,
	\tsim,  10,
	\y, 3,
	\x, 0,
	\buffer1, a,
	\buffer2, b,

	// \direction, passbyVars[\direction][idx].value,

]);
)
//////////////////////////////////////////////////////////////////////

// evaluate for GUI interface
(
// main window
var w = Window.new;
var scroll = ScrollView(bounds:Rect(120,100,1200,900));
var canvas = View(w);
var layout;
var i = 0;
var j = 0;
var defaultsPB = ();
var passbyVars = Dictionary.new();
var defaultsSC = Dictionary.new();
var sourceVars = Dictionary.new();
var nextNil =  {|list| if (list.indexOf(nil)==nil, {list.add(nil)}); list.indexOf(nil)};
var addEntry = {|dict, defaultsDict| var idx; dict.keysValuesDo({|key, val| idx=nextNil.(val); val.put(idx, defaultsDict[key].value)}); idx};
var remEntry = {|idx, dict| dict.do({ |list| list[idx]=nil })};
var srcDir = thisProcess.nowExecutingPath.dirname++"/sources";
var srcFiles = (srcDir++"/*.wav").pathMatch;
var statDir = thisProcess.nowExecutingPath.dirname++"/stationarySignals";
var statFiles = (statDir++"/*").pathMatch;
var findStatFile = {arg flist, v, rpm, prol; var i=0, out; while ( {(i < flist.size)},  { if (("V"++v).matchRegexp(PathName(flist[i]).fileName).and(("RPM"++rpm).matchRegexp(PathName(flist[i]).fileName)).and(prol.matchRegexp(PathName(flist[i]).fileName)), {out=PathName(flist[i]);i=flist.size}, {i=i+1})});out.fileName;};

// var synthargs = {|x|  }
/*var createSrc = {|vars, idx|
	Task({rep.do(Synth(key /* ITERATE OVER ARGS, */), exprand(time, 30).wait)})
};*/

var makeEntryPassby = {
	|idx|
	var view = View().background_(Color.fromHexString("#95A5A6")).layout_(
        HLayout(
			StaticText().string_( idx ).align_(\left).stringColor_(Color.white).font_(Font("Source Code Pro",size:32, bold:true)),
			StaticText().string_( ("Speed (km/h)") ).align_(\right),
			passbyVars[\speed][idx],
			StaticText().string_( ("RPM") ).align_(\right),
			passbyVars[\rpm][idx],
			StaticText().string_( ("T (sec)") ).align_(\right),
			passbyVars[\simT][idx],
			StaticText().string_( ("Y(m)") ),
			passbyVars[\y][idx],
			StaticText().string_( ("X(m)") ),
			passbyVars[\x][idx],
			StaticText().string_( ("ΔTmin (sec)") ).align_(\right),
			passbyVars[\passbyTmin][idx],
			StaticText().string_( ("ΔTmax (sec)") ).align_(\right),
			passbyVars[\passbyTmax][idx],
			StaticText().string_( ("Direction") ).align_(\right),
			passbyVars[\direction][idx],
			StaticText().string_( ("Prop") ).align_(\right),
			passbyVars[\ampa][idx],
			StaticText().string_( ("Roll") ).align_(\right),
			passbyVars[\ampb][idx],
			nil,
			Button().states_([["Start"], ["Stop", Color.black, Color.green]]).action_(
				{|val| if( val.value==1,{
					passbyVars[\buffer1][idx] = Buffer.alloc(s, s.sampleRate*30);
					passbyVars[\buffer2][idx] = Buffer.alloc(s, s.sampleRate*30);
					passbyVars[\task][idx] = Task({
						var wtime, speed, fname_prop, fname_roll;
						inf.do{
							wtime = exprand(passbyVars[\passbyTmin][idx].value,passbyVars[\passbyTmax][idx].value);
							speed = (passbyVars[\speed][idx].value) * (passbyVars[\direction][idx].value - 0.5)*(-2);

							fname_prop = statDir++"/"++findStatFile.(statFiles, abs(speed), passbyVars[\rpm][idx].value, "Prop").value;
							fname_roll = statDir++"/"++findStatFile.(statFiles, abs(speed), passbyVars[\rpm][idx].value, "Roll").value;

							passbyVars[\buffer1][idx] = Buffer.readChannel(s, fname_prop, channels:[0], bufnum: passbyVars[\buffer1][idx].bufnum);
							passbyVars[\buffer2][idx] = Buffer.readChannel(s, fname_roll, channels:[0], bufnum: passbyVars[\buffer2][idx].bufnum);

							// postln(passbyVars[\buffer1][idx].bufnum);
							// postln(passbyVars[\buffer1][idx].bufnum);
							s.sync;
							Synth(\passby, [
								\buffer1, passbyVars[\buffer1][idx].value,
								\buffer2, passbyVars[\buffer2][idx].value,
								\t_trig, 1,
								\ampa, passbyVars[\ampa][idx].value,
								\ampb, passbyVars[\ampb][idx].value,
								\amp,   ~amp.value,
								\gain, passbyVars[\gain][idx].value,
								\speed, speed,
								\tsim,  passbyVars[\simT][idx].value,
								\y, passbyVars[\y][idx].value,
								\x, passbyVars[\x][idx].value
							]);
						wtime.wait;
							// passbyVars[\buffer1][idx].free;
							// passbyVars[\buffer2][idx].free;
						}
					});
					passbyVars[\task][idx].play(AppClock);
					// passbyVars[\buffer1][idx].free;
					// passbyVars[\buffer2][idx].free;
				},
				{
					passbyVars[\task][idx].stop;
					passbyVars[\buffer1][idx].free;
					passbyVars[\buffer2][idx].free;
				});
				}
			),
			Button().states_([["Delete"]]).action_(
				{
					view.remove;
					passbyVars[\task][idx].stop;
					passbyVars[\buffer1][idx].free;
					passbyVars[\buffer2][idx].free;
					i = i - 1;
					remEntry.(idx, passbyVars)
			}),
			// Button().states_([["Delete"]]).action_({view.remove; passbyVars[\task][idx].stop; i = i - 1; remEntry.(idx, passbyVars)}),
			passbyVars[\gain][idx],
        )
    );
    i = i + 1;
	view;
};

var makeEntryStationary = {
	|idx|
	var view = View().background_(Color.fromHexString("#BDC3C7")).layout_(
        HLayout(
			StaticText().string_( idx ).align_(\left).font_(Font("Hasklig", size:32, bold:true)),
			StaticText().string_( ("File") ).align_(\right),
			sourceVars[\fname][idx],
			nil,
			StaticText().string_( ("Loop") ).align_(\right),
			sourceVars[\loop][idx],
			nil,
			StaticText().string_( ("T (sec)") ).align_(\right),
			sourceVars[\simT][idx],
			StaticText().string_( ("T=fileLength") ).align_(\right),
			sourceVars[\loopWhole][idx],
			nil,
			StaticText().string_( ("X(m)") ).align_(\right),
			sourceVars[\x][idx],
			StaticText().string_( ("Y(m)") ).align_(\right),
			sourceVars[\y][idx],
			StaticText().string_( ("Speed (km/h)") ).align_(\right),
			sourceVars[\speed][idx],
			nil,
			StaticText().string_( ("ΔTmin (sec)") ).align_(\right),
			sourceVars[\repeatTmin][idx],
			StaticText().string_( ("ΔTmax (sec)") ).align_(\right),
			sourceVars[\repeatTmax][idx],
			nil,
			Button().states_([["Start"], ["Stop", Color.black, Color.green]]).action_(
				{|val| if( val.value==1,{
					sourceVars[\task][idx] = Task({
						var wtime, buf, loops;
						if(sourceVars[\loop][idx].value, {loops=inf},{loops=1});
						(loops).do{
							sourceVars[\buffer][idx] = Buffer.readChannel(s, srcFiles[sourceVars[\fname][idx].value], channels:[0]);
							buf = Buffer.readChannel(s, srcFiles[sourceVars[\fname][idx].value].asString, channels:[0]);
							postln(buf.numFrames);
							if(sourceVars[\loopWhole][idx].value,
								{
									wtime = sourceVars[\buffer][idx].numFrames / sourceVars[\buffer][idx].sampleRate;
								},
								{
									wtime = exprand(sourceVars[\repeatTmin][idx].value,sourceVars[\repeatTmax][idx].value);
								};
							);
							Synth(\XYsource, [
								\t_trig, 1,
								\amp,   ~amp.value,
								\gain, sourceVars[\gain][idx].value,
								\speed, sourceVars[\speed][idx].value,
								\tsim,  sourceVars[\simT][idx].value,
								\y, sourceVars[\y][idx].value,
								\x, sourceVars[\x][idx].value,
								\buffer, sourceVars[\buffer][idx].value
							]);
							wtime.wait;
							sourceVars[\buffer][idx].free;
						}
					});
					sourceVars[\task][idx].play(AppClock);
					sourceVars[\buffer][idx].free;
				},
				{
					sourceVars[\task][idx].stop;
					sourceVars[\buffer][idx].free;
				});
				}
			),
            Button().states_([["Delete"]]).action_(
			{
				view.remove;
				j = j - 1;
				remEntry.(idx, sourceVars);
				sourceVars[\source][idx].free;
				sourceVars[\buffer][idx].free;

			}),
			sourceVars[\gain][idx]
        )
    );
    j = j + 1;
	view;
};


// s.options.memSize = 2.pow(16);
// s.waitForBoot;

defaultsPB[\buffer1] = {0};
defaultsPB[\buffer2] = {0};
defaultsPB[\speed] = {NumberBox.new().value_(50)};//.clipLo_(30).clipHi_(60)};
defaultsPB[\rpm] = {NumberBox.new().value_(2000)};//.clipLo_(30).clipHi_(60)};
defaultsPB[\y] = {NumberBox().value_(1)};
defaultsPB[\x] = {NumberBox().value_(0)};
defaultsPB[\simT] = {NumberBox().value_(5)};
defaultsPB[\passbyTmin] = {NumberBox().value_(5)};
defaultsPB[\passbyTmax] = {NumberBox().value_(10)};
defaultsPB[\direction] = {Button().states_([["       --->"], ["<---       "]]).value_(0)};
defaultsPB[\task] = {0};
defaultsPB[\gain] = {Knob().value_(1)};
defaultsPB[\ampa] = {NumberBox.new().value_(1.00).clipLo_(0.00).clipHi_(1.00).increment(0.001)};
defaultsPB[\ampb] = {NumberBox.new().value_(1.00).clipLo_(0.00).clipHi_(1.00).increment(0.001)};

// defaultsPB[\taskPB] = {| theTask vars| Task({ times.do })};

defaultsPB.keysDo({ |key| passbyVars[key]=List.newClear() });

defaultsSC[\fname] = {PopUpMenu().items_(srcFiles.collect{|i| PathName(i).fileName})};
defaultsSC[\buffer] = {0};
defaultsSC[\y] = {NumberBox().value_(20)};
defaultsSC[\x] = {NumberBox().value_(0)};
defaultsSC[\speed] = {NumberBox.new().value_(5)};//.clipLo_(30).clipHi_(60)};
defaultsSC[\source] = {0};
defaultsSC[\loop] = {CheckBox().value_(1)};
defaultsSC[\loopWhole] = {CheckBox().value_(1)};
defaultsSC[\repeatTmin] = {NumberBox().value_(5)};
defaultsSC[\repeatTmax] = {NumberBox().value_(10)};
defaultsSC[\simT] = {NumberBox().value_(5)};
defaultsSC[\gain] = {Knob().value_(1)};
defaultsSC[\task] = {0};

defaultsSC.keysDo({ |key| sourceVars[key]=List.newClear() });

layout = VLayout().margins_(1).spacing_(1);

// layout.add([HLayout(StaticText().string_("WFS").stringColor_(Color.black)), align:\center]);
layout.add( View().background_(Color.fromHexString("#6C7A89")).layout_(
    HLayout(
		Button().states_([[" Add passby "]]).action_({layout.insert(makeEntryPassby.(addEntry.(passbyVars, defaultsPB)), i+j)}),
		Button().states_([[" Add other "]]).action_({ layout.insert(makeEntryStationary.(addEntry.(sourceVars, defaultsSC)), i+j) }),
		// nil, // stretch remaining empty space
		// StaticText().string_("Array distance from window (m)").stringColor_(Color.white).align_(\right),
		// ~ys = NumberBox.new().value_(0.2),
		nil,
		StaticText().string_("Volume").stringColor_(Color.white).align_(\right),
		~amp = Knob.new().value_(0.5)
;
	)
));

canvas.layout = layout;
// canvas.font = "Hack";
// canvas.background = Color.black;
canvas.layout.add(nil); // stretch remaining empty space

scroll.canvas = canvas;
// w.canvas = canvas;
scroll.front;

)