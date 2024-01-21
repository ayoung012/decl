import {
	Length,
	LatLong,
	Angle,
	Colour,
	World,
	WorldDefinition,
	RenderableGraphic,
	Graphic,
	FontDescriptor,
	RenderingOptions,
	Mesher,
	GeoPolyline,
	Stroke
} from 'twinf'

const FPS = 60

const FACTOR = new Map([
	['+', 0.95],
	['-', 1.05],
])

class Animator
	constructor someFps, aCallback
		callback = aCallback
		fps = someFps;
		now = window.performance.now()
		lastFrame = window.performance.now()
		interval = 1000 / fps;
		delta = -1;
		handle = -1;
		let startflag = -1

	def start
		startflag = 1
		render()

	def stop
		startflag = -1
		window.cancelAnimationFrame(handle)

	get started
		startflag

	def render
		handle = window.requestAnimationFrame(do render!)
		now = window.performance.now()
		delta = now - lastFrame
		if (delta > interval)
			lastFrame = now - (delta % interval)
			callback()

export tag Canvas

	dpr = window.devicePixelRatio
	range = 2000

	def addGraphic g
		world.insert(g)

	def removeGraphic id
		world.delete(id)

	def start font, aCallback
		callback = aCallback
		const gl = $situ.getContext('webgl2')
		const offscreen = <canvas>
		const palantis = LatLong.ofDegrees(-7.9108, 44.6214)
		const wdef = new WorldDefinition(palantis, Length.ofKilometres(range), Angle.ofDegrees(0), Colour.LIGHTSLATEGRAY)
		world = new World(gl, wdef, new RenderingOptions({ pixelRatio: dpr }))

		world.loadSprites(offscreen, font)
		animator = new Animator(FPS, (do world.render()))
		animator.start()
		callback(world.centre(), world.range())

	def resized e
		$situ.width = offsetWidth * dpr
		$situ.height = offsetHeight * dpr

	def pan e
		unless ppos === undefined
			const maxX = ppos[0] - e.deltaX
			const maxY = ppos[1] - e.deltaY
			world.pan(maxX, maxY)
		ppos = [e.deltaX, e.deltaY]
		if e.isFinal
			ppos = undefined
		notify!

	def zoom e
		let factor
		if e.type === undefined
			factor = FACTOR.get(e);
		else if e.type == "pinch"
			if e.isLast
				pdist = undefined
				return
			if pdist === undefined
				pdist = e.scale
				return
			if Math.abs(pdist - e.scale) < 0.05
				return
			if e.additionalEvent == "pinchout"
				factor = 1.0 + (pdist - e.scale) /10
			else
				factor = 1.0 + (pdist - e.scale) /10

		unless factor === undefined || factor < 1.0 && world.range().kilometres() < 5
			world.setRange(world.range().scale(factor))
			range = Math.floor(world.range().kilometres())
			notify!

	def notify
		callback(world.centre(), world.range())

	<self
		@resize=resized
		@wheel
	>
		css w: 100% h: 100%
		<canvas$situ[pos:abs w:100% h:100%]>
