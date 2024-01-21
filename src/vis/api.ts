import { Graphic } from "twinf";

export interface Drawable {}

export interface DrawOnce extends Drawable {
    drawOnce(): Graphic
}

export interface DrawOnInterval extends Drawable {
    draw(): Graphic
}
