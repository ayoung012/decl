'use strict'

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
} from 'twinf';

import { TrackSymbol, TrackLeaderLine, TrackLabel } from './vis/tracks'

import { Track } from './domain/track'

import { fetchForImba } from './extern/fetch'

import { Canvas } from './ui/canvas.imba'

import Hammer from 'hammerjs'

global css body c:warm2 bg:warm8 ff:Arial inset:0 d:vcc p: 0 m: 0

const FONT_SIZE = 16
const SNAPSHOTS_PER_SECOND = 14

const INDEX_URL = "/index"
const INDEX_TYPE = "gardenhighrate"

class Events
	constructor
		els = {}

	def addEventListener name, handler
		if (els.hasOwnProperty(name))
			els[name].push(handler)
		else
			els[name] = [handler]

	def fireEvent name, data
		if (!this.els.hasOwnProperty(name))
			return
		const ls = this.els[name];
		const len = ls.length;
		for i in [ 0 .. len ]
			ls[i](data)

tag app

	prop now = undefined
	prop bufferSizePast = 15 * 60 * 1000
	prop bufferSizeFuture = 4 * 60 * 1000
	prop adj = undefined
	prop waiting = false
	prop error = false

	indices = []
	buffers = []
	cachedFrameIndex = -1
	currentBufferIndex = 0
	bufferedFrameIndex = -1
	respectScrobble = false

	trackCache = {}
	seenLast = {}

	def start e
		mc = new Hammer($situ)
		mc.get('pan').set({ direction: Hammer.DIRECTION_ALL });
		mc.on('pan', $situ.pan.bind($situ))
		mc.get('pinch').set({ enable: true })
		mc.on('pinch', $situ.zoom.bind($situ))

		const ff = new FontDescriptor('Arquette', FONT_SIZE * window.devicePixelRatio, new URL('./dist/ATCArquette-Medium.ttf', import.meta.url).href)

		$situ.start ff, this.rc.bind(this)

		const roller = new Date()
		roller.setDate(roller.getDate! - 2)
		roller.setUTCHours(0, 0, 0, 0)
		historical datestring roller

		now = roller.getTime()

	def setIndex d
		try
			fetchForImba(INDEX_URL + '/' + INDEX_TYPE + '-' + d + '.txt')
			.then(do(res)
				if (!res.ok)
					error = true
					throw Error('index not found: ' + d)
				error = false
				res.text()
			)
			.then(do(text)
				console.log(text)
				const result = text.split(/\r?\n/)
				result.shift() # version
				indices = result.slice()
			)

	def historical d
		const initBuffer = 0
		setIndex(d)
		.then(do
			fetchHighRateTracksAt(indices[initBuffer])
		)
		.then(do(frame)
			buffers[initBuffer] = frame
			bufferedFrameIndex = initBuffer
			now = frame[initBuffer].now * 1000
		)
		.then(do
			setInterval self.tick.bind(self, "bananas"), 1000 / SNAPSHOTS_PER_SECOND
		)
		.then(do
			highRateBuffer!
			highRateBufferedChurn!
		)

	def highRateBufferedChurn
		if (buffers.length == 0 || currentBufferIndex > bufferedFrameIndex)
			console.log("caught up with buffer, waiting...")
			waiting = true
			new Promise(do(resolve) setTimeout(resolve, 1000))
			.then(do highRateBufferedChurn!)
			return
		waiting = false
		new Promise(do(resolve)
			churnFrames buffers[currentBufferIndex].slice(), resolve
		)
		.then(do new Promise(do(resolve) setTimeout(resolve, 100)))
		.then(do
			if (!respectScrobble)
				currentBufferIndex++
			highRateBufferedChurn!
		)

	def churnFrames frames, resolve
		if (frames.length == 0)
			resolve!
			return
		if (now < frames[0].now * 1000)
			new Promise(do(done) setTimeout(done, 1000 / SNAPSHOTS_PER_SECOND))
				.then(do churnFrames frames, resolve)
			return

		const frame = frames.shift()
		# this.now = frame.now * 1000
		const states = frame.aircraft.filter(do(a) a.lat != null)
		const tracks = states.map(Track.parseSurv)
		new Promise(do(done)
			processTracks tracks
			# render!
			done!
		)
		.then(do new Promise(do(done) setTimeout(done, 1000 / SNAPSHOTS_PER_SECOND)))
		.then(do churnFrames frames, resolve)

	def datestring d
		return d.getFullYear() + ("0"+(d.getMonth()+1)).slice(-2) + ("0" + d.getDate()).slice(-2)

	def fetchHighRateTracksAt url
		fetchForImba('/' + INDEX_TYPE + '/' + url)
		.then(do(res) res.json())
		.catch(do(err)
			console.log("there was an error churning snapshot: " + url)
			console.log(err)
			return []
		)

	def processTracks tracks
		const seenThisFrame = []
		for t in tracks
			unless t.position !== undefined
				continue
			seenThisFrame.push(t.icao24)
			this.trackCache[t.icao24] = t
			$situ.addGraphic(new TrackSymbol(t).draw())
			$situ.addGraphic(new TrackLeaderLine(t).draw())
			$situ.addGraphic(new TrackLabel(t).draw())

		const notSeen = Object.keys(this.seenLast).filter(do(t)
			return seenThisFrame.indexOf( t ) < 0
		)
		for t in notSeen
			this.seenLast[t] = this.seenLast[t] - 1
			if this.seenLast[t] < -5
				$situ.removeGraphic(t)
				$situ.removeGraphic(t+'l')
				$situ.removeGraphic(t+'ll')
				delete this.seenLast[t]
				delete this.trackCache[t]
			else
				$situ.addGraphic(new TrackSymbol(this.trackCache[t], this.seenLast[t]).draw())
				$situ.removeGraphic(t+'l')
				$situ.removeGraphic(t+'ll')
		if notSeen.length != 0
			console.log(notSeen)
		for t in seenThisFrame
			this.seenLast[t] = 0


	def rc aCentre, aRange
		range = Math.floor(aRange.kilometres())
		render!

	def isoTime date
		if date === undefined
			return "-"
		else
			return date.toISOString().substr(0, 19).substr(-8)

	def clock
		if now === undefined
			return "-"
		let date = new Date now
		return isoTime date

	def blink ink, onk, ulk
		const sec = new Date!.getSeconds!
		if ulk != undefined
			if error
				ulk
			else
				const quake = [ink, onk, ulk]
				quake[sec % 3]
		else
			sec % 2 == 0 ? ink : onk

	def tick term
		if term != "bananas"
			render!
			return
		if waiting
			return
		now += 1000
		render!

	def changeDate d
		console.log("caching new date: " + d.detail)
		const newFrameIndex = 0
		setIndex(d.detail)
		.then(do
			fetchHighRateTracksAt(indices[newFrameIndex])
		)
		.then(do(frame)
			buffers = []
			buffers[newFrameIndex] = frame
			bufferedFrameIndex = newFrameIndex
			currentBufferIndex = newFrameIndex
			now = frame[0].now * 1000
			respectScrobble = true
		)

	def scrobble e
		const newFrameIndex = Math.trunc(indices.length * (e.detail / 86400))
		console.log("caching new frame for scrobble: " + newFrameIndex)
		fetchHighRateTracksAt(indices[newFrameIndex])
		.then(do(frame)
			buffers[newFrameIndex] = frame
			bufferedFrameIndex = newFrameIndex
			now = frame[0].now * 1000
			currentBufferIndex = newFrameIndex
			respectScrobble = true
		)

	def highRateBuffer
		if indices.length == 0 || indices.length <= bufferedFrameIndex
			console.log("run out of indices!")
			error = true
			return new Promise(do(resolve) setTimeout(resolve, 1000))
				.then(do highRateBuffer!)
		if error
			error = false

		if buffers.length != 0 && buffers[bufferedFrameIndex].length == 0
			console.log("an error occured interpreting frame: " + bufferedFrameIndex)
		else if buffers.length != 0 && buffers[bufferedFrameIndex][0].now * 1000 > now + bufferSizeFuture
			console.log("cached enough into the future, nothing to do")
			new Promise(do(resolve) setTimeout(resolve, 1000))
				.then(do highRateBuffer!)
			return

		const newFrameIndex = bufferedFrameIndex + 1
		fetchHighRateTracksAt(indices[newFrameIndex])
		.then(do(frame)
			if (!respectScrobble)
				buffers[newFrameIndex] = frame
				bufferedFrameIndex += 1
			else
				respectScrobble = false
		)
		.then(do highRateBuffer!)

	def nowInSeconds
		let date = new Date now
		let zero = new Date now
		zero.setUTCHours(0, 0, 0, 0)
		return (date.getTime! - zero.getTime!) / 1000

	<self
		@resize.once=start
		@wheel
	>
		css w: 100% h: 100%
		<Canvas$situ>
			css pos:rel z-index:10
		<div.controls>
			css pos:abs r:0px l:0 t:0px b:0 font-family:monospace
			<%hud>
				css z-index:1000 pos:rel
				<div.range>
					css pos:abs p:4px r:0 w:4em e:250ms us:none bg:gray9 d:hcc g:1
						bd:1px solid transparent @hover:indigo5
					range
				<div.time autorender=1s>
					css fs:1.6em p:4px 12px mr:0 w:4em e:250ms us:none bg:gray9 d:hcc g:1
						bd:1px solid transparent @hover:indigo5
						text-align:right
					<span[visibility:{ waiting || error ? "visible" : "hidden" } color:{ error ? "red" : "white" }]>
						blink("\"", "-", ".")
					clock!
					<span[visibility:hidden]>
						"."
				<div.adj[display:{ adj == undefined ? "none" : "flex" }]>
					css fs:1.6em p:4px 12px mr:0 w:4em e:250ms us:none c:darkgray bg:gray9 d:hcc g:1
						bd:1px solid transparent @hover:indigo5
					<span[visibility:{ blink("visible", "hidden") }]>
						nowInSeconds! - adj < 0 ? "+" : "-"
					adj === undefined ? "-" : isoTime new Date(Math.abs(nowInSeconds! - adj) * 1000)
					<span[visibility:hidden]>
						"."
			<control-range handler=$situ.zoom.bind($situ)>
				css z-index:1000 w:20px pos:inherit t:20px r:0
			<control-time bind:now=now bind:adj=adj autorender=1s @scrobble=scrobble @changeDate=changeDate>
				css z-index:1000 w:100% pos:inherit b:0

imba.mount <app autorender=1s>
