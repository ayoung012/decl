import { Colour, GeoRelativeCircle, GeoRelativePolygon, GeoRelativePolyline, GeoRelativeText, Graphic, Offset, Paint, Stroke } from "twinf";
import { DrawOnInterval } from "./api";
import { Track } from "../domain/track";

abstract class TrackRelatedGraphic {
    protected track: Track
    protected lastSeen: number
    constructor(track: Track, lastSeen: number = 0) {
        this.track = track
        this.lastSeen = lastSeen
    }
}

export class TrackSymbol extends TrackRelatedGraphic {
    draw(): Graphic {
        const colour = (this.lastSeen >= -1) ? Colour.WHITE : Colour.GHOSTWHITE
        const radius = 5 + this.lastSeen
        const m = new GeoRelativeCircle(
            this.track.position,
            new Offset(0, 0),
            radius,
            Paint.stroke(new Stroke(colour, 2))
            )
        return new Graphic(this.track.icao24, -1, [m])
    }
}

export class TrackLeaderLine extends TrackRelatedGraphic {
    draw(): Graphic {
        const ll = new GeoRelativePolyline(
            this.track.position,
            [new Offset(8,8), new Offset(20, 20)],
            new Stroke(Colour.DARKSLATEGRAY, 1)
        )
        return new Graphic(this.track.icao24+'ll', -1, [ll])
    }

    delete(): boolean {
        return lastSeen <= -2
    }
}

export class TrackLabel extends TrackRelatedGraphic {
    labelTrackOffsetPx = 20
    labelPaint = Paint.complete(new Stroke(Colour.rgb(0, 0, 0), 2), Colour.rgb(30, 30, 30));

    labelOffsets = [
        new Offset(20, 20),
        new Offset(20, 52),
        new Offset(90, 52),
        new Offset(90, 20)
    ];
    callsignFieldOffset = new Offset(this.labelTrackOffsetPx, this.labelTrackOffsetPx);
    altFieldOffset = new Offset(this.labelTrackOffsetPx, this.labelTrackOffsetPx + 15);
    draw(): Graphic {
        const l = new GeoRelativePolygon(this.track.position, this.labelOffsets, this.labelPaint);
        const c = new GeoRelativeText(this.track.position,
            this.callsignFieldOffset,
            Colour.WHITE,
            this.track.callsign ? this.track.callsign : '*' + this.track.icao24)
        let lrfText: string
        if (this.track.baroAltitude) {
            const feet = this.track.baroAltitude.feet() + ""
            lrfText = feet.substring(0, feet.length - 2).padStart(3, '0')
        } else {
            lrfText = 'lrf'
        }
        const alt = new GeoRelativeText(this.track.position,
            this.altFieldOffset,
            Colour.WHITE,
            lrfText)
        return new Graphic(this.track.icao24+'l', -1, [l, c, alt])
    }

    delete(): boolean {
        return lastSeen <= -2
    }
}
