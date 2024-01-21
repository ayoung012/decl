import { Angle, LatLong, Length, Speed } from "twinf"

enum PositionSource {
    ADSB,
    ASTERIX,
    MLAT
}
export class Track {
    icao24: string
    callsign: string
    country: string
    position: LatLong
    lastContact: number
    onGround: boolean
    spi: boolean
    timePosition: number
    positionSource: any
    baroAltitude: Length
    velocity: Speed
    trueBearing: Angle
    verticalRate: Speed
    geoAltitude: Length
    squawk: number

    private constructor() {
        /* empty. */
    }
    static parseSurv(obj) {
        let res = new Track();
        res.icao24 = obj.hex;
        if (obj.flight) {
            res.callsign = obj.flight.trim();
        }
        res.lastContact = obj.seen;
        if (obj.lat !== null && obj.lon !== null) {
            res.position = LatLong.ofDegrees(obj.lat, obj.lon);
        }
        if (obj.alt_baro !== null) {
            res.baroAltitude = Length.ofFeet(obj.alt_baro);
        }
        res.squawk = obj.squawk;
        res.positionSource = PositionSource.ADSB;
        return res;
    }
}
