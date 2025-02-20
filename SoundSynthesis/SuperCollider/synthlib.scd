(
SynthDef(\moog, {
	arg freq = 120, amp = 1, exc = 1, cutoff = 2000, res = 0.5, speed = 2, depth = 0.0, detune = 0, pan = 0.0, out = 0;
	var sig;
	freq = freq + (freq * (Rand(-1.0, 1.0) * detune));
	sig = Pulse.ar([freq/2.98, freq], [0.3, 0.7]) * exc;
	sig = Pan2.ar(sig[0], pan-0.3) + Pan2.ar(sig[1], pan+0.3);
	sig = MoogFF.ar(sig, cutoff * SinOsc.ar(speed, 0.0, depth, 0.5), res * 4) * 0.2 * amp;
	Out.ar(out, sig);
}).add;


SynthDef(\noise, {
	arg amp = 1, exc = 1, freq_gain = 1, freq = 150, moog_gain = 0, pan = 0.6, out = 0;
	var sig;
	sig = WhiteNoise.ar(0.4) * exc;
	sig = MoogFF.ar(sig, freq, moog_gain) * freq_gain;
	sig = sig * amp * 0.7;
	sig = Pan2.ar(sig, pan);
	Out.ar(out, sig);
}).add;

/*
// replace the noise with pink noise or Moog Filter + Brown noise frokm test.scd
SynthDef(\noise, {
	arg amp = 1, exc = 1, freq = 150, bw = 10, out = 0;
	var sig;
	sig = WhiteNoise.ar(0.25) * exc;
	sig = BBandPass.ar(sig, freq, bw);
	sig = sig * amp * 0.4 * (20-(bw.explin(0.01, 0.4, 0, 19))); //is this working corretcly?
	Out.ar(out, [sig, sig]);
}).add;
*/

SynthDef(\saw, {
	arg amp = 1, exc = 1, degree = 12, detune = 1.01, dist = 0.5, out = 0;
	var temp, sig = 0, scale = Scale.minorPentatonic;
	10.do{
		temp = VarSaw.ar(
			(DegreeToKey.kr(scale.as(LocalBuf), degree, scale.stepsPerOctave, 1, 60)).midicps * {Rand(-1.0,1.0).range(detune.reciprocal, detune)}!2,
			{Rand(0.0, 1.0)}!2,
			{ExpRand(0.01, 0.2)}!2
		);
		sig = sig + temp;
	};
	sig = sig * 0.01 * exc;
	sig = Disintegrator.ar(sig, 0.5, dist.linlin(0.0, 1.0, 1.0, 0.0));
	sig = sig * amp;
	Out.ar(out, sig);
}).add;


SynthDef(\lead, {
	arg amp = 1, exc = 1, degree = 7, detune = 0.04, out = 0, pan = 0.9;
	var scale, buffer, sig;
	scale =  FloatArray[0, 3, 5, 7, 10]; // dorian scale FloatArray[0, 2, 3.2, 5, 7, 9, 10];
	buffer = Buffer.alloc(s, scale.size,1, {|b| b.setnMsg(0, scale) });

	sig = SinOsc.ar(
		(
			DegreeToKey.kr(buffer.bufnum, degree,
				12,                    // 12 notes per octave
				1,                    // mul = 1
				72                    // offset by 72 notes
			)
			+ LFNoise1.kr([3,3], detune)    // add some low freq stereo detuning
		).midicps,                        // convert midi notes to hertz
		0,
		0.1);

	// add some 70's euro-space-rock echo
	sig = sig * exc * 0.4;
	sig = CombN.ar(sig, 0.2, 0.2, 0.5, 1, sig) * amp;
	sig = Pan2.ar(Mix.ar(sig), pan);
	Out.ar(out, sig);
}).add;


SynthDef(\kling, {
	arg amp = 1, exc = 1, dens = 1, freq = 1000, dev = 1.01, lfodepth = 10, decay = 1.0, wide = 0.02, pan = 0.0, out = 0;
	var sig;
	sig = {arg count; Impulse.ar(dens, count * wide, exc * 0.2) * LFNoise0.kr(10, 0.5, 0.5)}!2;
	sig = Ringz.ar(sig, [
		LFSaw.kr(dens, 0.0).range(freq - lfodepth, freq),
		LFSaw.kr(dens, 1.0).range(freq, freq + lfodepth) * dev
	], decay);
	sig = Pan2.ar(sig[0], (-0.2 + pan)) + Pan2.ar(sig[1], (0.2 + pan));//Mix.new(sig * amp);
	sig = sig * amp;
	Out.ar(out, sig);
}).add;


SynthDef.new(\sine, {
	arg amp=1, exc = 1, freq=440, atk=0.005, rel=0.3, shape = 0, pan=0, out=0;
	var sig, osc1, osc2, env;
	osc1 = SinOsc.ar(freq) * exc;
	osc2 = VarSaw.ar(freq) * exc;
	sig = (osc1 * (1-shape)) + (osc2 * shape);
	env = EnvGen.kr(Env.new([0, 1, 0], [atk, rel], [1,-1]), doneAction:2);
	sig = Pan2.ar(sig, pan, amp);
	sig = sig * env;
	Out.ar(out, sig);
}).add
)