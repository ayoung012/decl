tag control-range

	ppos = undefined

	def swipe e
		if e.phase == "ended"
			ppos = undefined
			return
		if ppos === undefined
			ppos = e.y
			return

		if ppos - 5 > e.y # up
			handler('+')
			ppos = e.y
		else if ppos + 5 < e.y # down
			handler('-')
			ppos = e.y

	<self>
		<div.range>
			css pos:rel r:5px t:0px w:20px height:200px mt:10px
			<div.range.decrease @click=handler('+')>
				css w:20px h:20px e:250ms us:none bg:gray9 d:hcc g:1
					bd:1px solid transparent @hover:indigo5
				"+"
			<div.range.bar @touch.prevent.moved.fit(self)=swipe>
				css w:6px height:100% m:5px auto
					bg: gray9 border-radius:3px
			<div.range.increase @click=handler('-')>
				css w:20px h:20px e:250ms us:none bg:gray9 d:hcc g:1
					bd:1px solid transparent @hover:indigo5
				"-"

tag control-time

	prop now
	prop seconds = 0
	prop adj = undefined
	prop activeInteraction = false

	def changeDate e
		if e.phase != "ended"
			return
		console.log(e)
		const d = e.target.innerText.replaceAll("-","")
		emit('changeDate', d)

	def handler e
		if e.phase == "init"
			activeInteraction = true
		adj = e.x
		seconds=e.x
		if e.phase == "ended"
			activeInteraction = false
			adj = undefined
			emit("scrobble", e.x)
		render!

	def date adjDays
		if now === undefined
			return "-"
		let date = new Date now
		if adjDays
			date.setDate(date.getDate() + adjDays)
		return date.toISOString().substr(0, 10)

	def nowInSeconds
		let date = new Date now
		let zero = new Date now
		zero.setUTCHours(0, 0, 0, 0)
		return (date.getTime! - zero.getTime!) / 1000

	<self>
		<div.time>
			css w:90% height:30px mb:10px ml:auto mr:auto font-size:0.8em font-family:monospace
			<fieldset[p:0 h:100% d:grid gaf:column ja:center g:0 border-top:0 border-bottom:0]>
				<div.box @touch=changeDate>
					css c:black padding: 1em 10px 0 5px bg:#F3F3F3 border:1px #DADADA solid
					date -1
				<div.box @touch.fit(0,85399)=handler>
					css pos:relative w:800px bg:#4C8FFB border:1px #3079ED solid
					<div>
						css padding: 1em 10px 0 5px
						date!
					<div>
						css pos:absolute bg:red
							t:0 l:{ (nowInSeconds! * 800 / 85399) - 2 }px
							width:3px height:2.8em margin-top:-0.3em
					<div>
						css pos:absolute bg:darkred
							visibility:{ activeInteraction ? "visible" : "hidden" }
							t:0 l:{ (adj * 800 / 85399) - 2 }px
							width:3px height:2.8em margin-top:-0.3em
				<div.box @touch=changeDate>
					css c:black padding: 1em 10px 0 5px bg:#F3F3F3 border:1px #DADADA solid
					date 1
				<div.box @touch=changeDate>
					css c:black padding: 1em 10px 0 5px bg:#F3F3F3 border:1px #DADADA solid
					date 2
