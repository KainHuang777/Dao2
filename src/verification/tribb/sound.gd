extends RefCounted
## TRIB-B-F1: original filtered-noise thunder, no samples or gameplay RNG.
## Cloud rolls precede the bolts; nearby cracks lead a broad rolling stereo tail.
const RATE := 22050
const DURATION := 20
const STRIKES := [7.6,9.3,11.1]
const PREMONITIONS := [.65,3.65]
const POWERS := [.80,.94,1.08]
const REFLECTIONS := [[.071,.109,.19],[.193,.251,.16],[.417,.349,.12],[.691,.773,.08]]

static func make(failed: bool) -> AudioStreamWAV:
	var dry := PackedFloat32Array()
	dry.resize(RATE*DURATION)
	var seed := 137
	var bass := 0.0
	var low := 0.0
	var body := 0.0
	var air := 0.0
	var envelope_noise := 0.0
	for i in dry.size():
		var t := float(i)/RATE
		seed=(seed*48271)%2147483647
		var n := float(seed)/1073741823.5-1.0
		# Approximate 60, 180, 500 and 2200 Hz low-pass noise bands.
		bass += .017*(n-bass)
		low += .050*(n-low)
		body += .133*(n-body)
		air += .466*(n-air)
		envelope_noise += .0004*(n-envelope_noise)
		var rumble := bass*3.6+(low-bass)*2.0+(body-low)*.65
		var roll := .72+clampf(absf(envelope_noise)*28.0,0,.65)
		var v := body*.018*smoothstep(0,.8,t)*(1-smoothstep(16,20,t))
		for cue in PREMONITIONS:
			var dt: float=t-cue
			if dt>=0 and dt<4.0:
				v += rumble*smoothstep(0,.65,dt)*exp(-dt*.68)*roll*.38
		for index in STRIKES.size():
			var dt: float=t-STRIKES[index]
			if dt<0 or dt>5.0: continue
			var power: float=POWERS[index]
			# Noise attack and clustered cracks replace the old sine chirp.
			var crack := smoothstep(0,.0015,dt)*exp(-dt*27.0)
			crack += .33*smoothstep(.036,.038,dt)*exp(-maxf(0,dt-.038)*48.0)
			crack += .19*smoothstep(.092,.095,dt)*exp(-maxf(0,dt-.095)*38.0)
			v += power*(air*.70+(n-air)*.10)*crack
			var delayed := maxf(0,dt-.085)
			var tail := smoothstep(.025,.16,dt)*exp(-delayed*.95)
			var rolling := 1.0+.24*sin(delayed*13.0+index)+.13*sin(delayed*23.3)
			v += power*rumble*tail*rolling*roll*.70
		if t>=12.4 and t<16.0:
			var dt := t-12.4
			v += (sin(TAU*(71.0 if failed else 220.0)*dt)+sin(TAU*(93.0 if failed else 330.0)*dt))*.026*smoothstep(0,.08,dt)*exp(-dt*.9)
		dry[i]=v
	var bytes := PackedByteArray()
	bytes.resize(dry.size()*4)
	for i in dry.size():
		var left := dry[i]
		var right := dry[i]
		# Actual delayed reflections, with different paths to each ear.
		for reflection in REFLECTIONS:
			var l := i-roundi(reflection[0]*RATE)
			var r := i-roundi(reflection[1]*RATE)
			if l>=0: left+=dry[l]*reflection[2]
			if r>=0: right+=dry[r]*reflection[2]
		var fade := 1.0-smoothstep(18.5,20.0,float(i)/RATE)
		# Smooth headroom instead of a hard clipped transient.
		left=tanh(left*1.75)*.84*fade
		right=tanh(right*1.75)*.84*fade
		bytes.encode_s16(i*4,roundi(left*32767.0))
		bytes.encode_s16(i*4+2,roundi(right*32767.0))
	var wav := AudioStreamWAV.new()
	wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=RATE
	wav.stereo=true
	wav.data=bytes
	return wav
