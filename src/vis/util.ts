import { Colour, GeoPolyline, LatLong, Stroke } from "twinf";

const geoPolyline = (coordinates:number[][], colour = Colour.ALICEBLUE, swapped = true, stroke) => {
	const positions = new Array();
	for (const coord of coordinates) {
		/* longitude first, then latitude. */
		const a: number = coord[0]
		const b: number = coord[1]

		const point = swapped ? LatLong.ofDegrees(b, a) : LatLong.ofDegrees(a, b)
		positions.push(point)
	}
	return new GeoPolyline(positions, stroke ? stroke : new Stroke(colour, 1))
}

export { geoPolyline }
