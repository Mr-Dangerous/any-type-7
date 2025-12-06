# Planet Generation Logic

This file contains the core JavaScript logic for generating rocky and gas planets, extracted from `planet_generator.html`.

## Perlin Noise

The planet generation is based on 3D Perlin noise. Here is the implementation of the Perlin noise generator:

```javascript
// --- 3D Perlin Noise Implementation ---
const Perlin = {
    rand_vect_3d: function(){
        let theta = Math.random() * 2 * Math.PI;
        let phi = Math.acos(2 * Math.random() - 1);
        let sinPhi = Math.sin(phi);
        return {x: Math.cos(theta) * sinPhi, y: Math.sin(theta) * sinPhi, z: Math.cos(phi)};
    },
    dot_prod_grid_3d: function(x, y, z, vx, vy, vz){
        let g_vect;
        let d_vect = {x: x - vx, y: y - vy, z: z - vz};
        const key = `${vx},${vy},${vz}`;
        if (this.gradients[key]){
            g_vect = this.gradients[key];
        } else {
            g_vect = this.rand_vect_3d();
            this.gradients[key] = g_vect;
        }
        return d_vect.x * g_vect.x + d_vect.y * g_vect.y + d_vect.z * g_vect.z;
    },
    smootherstep: function(x){
        return 6*x**5 - 15*x**4 + 10*x**3;
    },
    interp: function(x, a, b){
        return a + this.smootherstep(x) * (b-a);
    },
    seed: function(s) {
        let seededRandom = function() {
            let x = Math.sin(s++) * 10000;
            return x - Math.floor(x);
        };
        this.gradients = {};
        this.memory = {};
        this.rand_vect_3d = function(){
            let theta = seededRandom() * 2 * Math.PI;
            let phi = Math.acos(2 * seededRandom() - 1);
            let sinPhi = Math.sin(phi);
            return {x: Math.cos(theta) * sinPhi, y: Math.sin(theta) * sinPhi, z: Math.cos(phi)};
        };
    },
    get3D: function(x, y, z) {
        const key = `${x.toFixed(3)},${y.toFixed(3)},${z.toFixed(3)}`;
        if (this.memory[key]) return this.memory[key];

        let xf = Math.floor(x);
        let yf = Math.floor(y);
        let zf = Math.floor(z);

        let c000 = this.dot_prod_grid_3d(x, y, z, xf,   yf,   zf);
        let c100 = this.dot_prod_grid_3d(x, y, z, xf+1, yf,   zf);
        let c010 = this.dot_prod_grid_3d(x, y, z, xf,   yf+1, zf);
        let c110 = this.dot_prod_grid_3d(x, y, z, xf+1, yf+1, zf);
        let c001 = this.dot_prod_grid_3d(x, y, z, xf,   yf,   zf+1);
        let c101 = this.dot_prod_grid_3d(x, y, z, xf+1, yf,   zf+1);
        let c011 = this.dot_prod_grid_3d(x, y, z, xf,   yf+1, zf+1);
        let c111 = this.dot_prod_grid_3d(x, y, z, xf+1, yf+1, zf+1);

        let c00 = this.interp(x - xf, c000, c100);
        let c01 = this.interp(x - xf, c001, c101);
        let c10 = this.interp(x - xf, c010, c110);
        let c11 = this.interp(x - xf, c011, c111);

        let c0 = this.interp(y - yf, c00, c10);
        let c1 = this.interp(y - yf, c01, c11);

        let val = this.interp(z - zf, c0, c1);
        this.memory[key] = val;
        return val;
    }
};
```

## Color Palettes

The color of the planet is determined by a palette, which is an array of color stops. The `getColor` function selects a color from the palette based on a noise value.

```javascript
const palettes = {
    rocky: [
        { limit: -0.3, color: '#223B75' },{ limit: 0.0, color: '#3A5E95' },{ limit: 0.3, color: '#4D7D4B' },
        { limit: 0.6, color: '#7BAB79' },{ limit: 0.8, color: '#947761' },{ limit: 1.1, color: '#FFFFFF' },
    ],
    gas_palettes: [
        [ { limit: -0.5, color: '#5A3010' }, { limit: -0.2, color: '#8A4A22' },{ limit: 0.1, color: '#B35E2D' }, { limit: 0.4, color: '#D87D43' }, { limit: 1.1, color: '#F0A96B' } ],
        [ { limit: -0.6, color: '#1B2C5A' }, { limit: -0.3, color: '#2C4A8A' }, { limit: 0.0, color: '#5B7ABD' }, { limit: 0.3, color: '#A2B8E0' }, { limit: 1.1, color: '#DDEEFF' } ],
        [ { limit: -0.5, color: '#8C7B5A' }, { limit: -0.2, color: '#A08F6E' }, { limit: 0.1, color: '#C4B598' }, { limit: 0.4, color: '#DCD0B5' }, { limit: 1.1, color: '#F0EAD6' } ],
        [ { limit: -0.5, color: '#1E4D2B' }, { limit: -0.2, color: '#2A6A3D' }, { limit: 0.1, color: '#4F9D69' }, { limit: 0.4, color: '#86C198' }, { limit: 1.1, color: '#C5E2CF' } ],
        [ { limit: -0.6, color: '#4A0000' }, { limit: -0.3, color: '#7B0000' }, { limit: 0.0, color: '#A82A2A' }, { limit: 0.3, color: '#D45C5C' }, { limit: 1.1, color: '#F09B9B' } ],
        [ { limit: -0.5, color: '#3B1E4D' }, { limit: -0.2, color: '#5C2A6A' }, { limit: 0.1, color: '#864F9D' }, { limit: 0.4, color: '#B486C1' }, { limit: 1.1, color: '#DDC5E2' } ],
        [ { limit: -0.5, color: '#664200' }, { limit: -0.2, color: '#996300' }, { limit: 0.1, color: '#CC8500' }, { limit: 0.4, color: '#FFB733' }, { limit: 1.1, color: '#FFD788' } ],
        [ { limit: -0.5, color: '#3D2B1F' }, { limit: -0.2, color: '#5A3F2F' }, { limit: 0.1, color: '#90B098' }, { limit: 0.4, color: '#B8D8C0' }, { limit: 1.1, color: '#E0F0E8' } ],
        [ { limit: -0.5, color: '#3A5FCD' }, { limit: -0.2, color: '#6495ED' }, { limit: 0.1, color: '#87CEEB' }, { limit: 0.4, color: '#B0E0E6' }, { limit: 1.1, color: '#F0FFFF' } ],
        [ { limit: -0.5, color: '#6A4A4A' }, { limit: -0.2, color: '#8A6A6A' }, { limit: 0.1, color: '#B08080' }, { limit: 0.4, color: '#D8A0A0' }, { limit: 1.1, color: '#F5D0D0' } ],
        [ { limit: -0.5, color: '#3D4024' }, { limit: -0.2, color: '#556B2F' }, { limit: 0.1, color: '#6B8E23' }, { limit: 0.4, color: '#9ACD32' }, { limit: 1.1, color: '#C0E080' } ],
        [ { limit: -0.6, color: '#240046' }, { limit: -0.3, color: '#3C096C' }, { limit: 0.0, color: '#5A189A' }, { limit: 0.3, color: '#9D4EDD' }, { limit: 1.1, color: '#E0AAFF' } ]
    ]
};
```

## Planet Generation

The `generatePlanet` function generates the planet image data. It uses the Perlin noise generator to create the planet's surface and the color palettes to color it.

```javascript
function generatePlanet(isSpriteSheet = false) {
    // These UI elements would need to be sourced from the new tool's UI
    const resolution = parseInt(ui.resolution.value);
    const planetType = ui.planetType.value;
    const seed = parseInt(ui.seed.value);
    const noiseScale = parseFloat(ui.noiseScale.value) / 100;
    const octaves = parseInt(ui.octaves.value);
    const rarity = ui.rarity.value;

    Perlin.seed(seed);

    const frameCount = isSpriteSheet ? 8 : 1;
    ui.canvas.width = resolution * frameCount;
    ui.canvas.height = resolution;
    ui.ctx.clearRect(0, 0, ui.canvas.width, ui.canvas.height);

    let palette;
    let axialTiltRad = 0;
    if (ui.axialTilt.checked) {
        const tiltDegrees = (seed % 51) - 25;
        axialTiltRad = tiltDegrees * (Math.PI / 180);
    }
    
    if (planetType === 'gas') {
        palette = palettes.gas_palettes[seed % palettes.gas_palettes.length];
    } else if (planetType === 'rocky') {
        palette = palettes.rocky;
    }
    // ... logic for other planet types would go here

    const rarityColor = rarity !== 'none' ? rarityTints[rarity] : null;

    const sinAxialTilt = Math.sin(axialTiltRad);
    const cosAxialTilt = Math.cos(axialTiltRad);

    for (let frame = 0; frame < frameCount; frame++) {
        const imageData = ui.ctx.createImageData(resolution, resolution);
        const data = imageData.data;
        const spinRad = (frame / frameCount) * 2 * Math.PI;
        const sinSpin = Math.sin(spinRad);
        const cosSpin = Math.cos(spinRad);

        for (let y = 0; y < resolution; y++) {
            for (let x = 0; x < resolution; x++) {
                const u = (x - resolution/2) / (resolution/2);
                const v = (y - resolution/2) / (resolution/2);
                const distSq = u*u + v*v;

                if (distSq > 1) continue;

                const w = Math.sqrt(1 - distSq);
                
                let px = u, py = v, pz = w;

                let px_spun = px * cosSpin - pz * sinSpin;
                let py_spun = py;
                let pz_spun = px * sinSpin + pz * cosSpin;

                let px_tilted = px_spun * cosAxialTilt - py_spun * sinAxialTilt;
                let py_tilted = px_spun * sinAxialTilt + py_spun * cosAxialTilt;
                let pz_tilted = pz_spun;
                
                let noiseVal = 0;
                let frequency = 1;
                let amplitude = 1;
                let maxAmplitude = 0;

                for (let i = 0; i < octaves; i++) {
                    noiseVal += Perlin.get3D(
                        px_tilted * frequency / noiseScale, 
                        py_tilted * frequency / noiseScale, 
                        pz_tilted * frequency / noiseScale
                    ) * amplitude;
                    maxAmplitude += amplitude;
                    amplitude *= 0.5;
                    frequency *= 2;
                }
                noiseVal /= maxAmplitude;

                if (planetType === 'gas') {
                    const bandSignal = Math.sin(py_tilted * 15.0);
                    noiseVal = (noiseVal * 0.7) + (bandSignal * 0.3);
                }

                const colorHex = getColor(noiseVal, palette);
                let finalColor = hexToRgb(colorHex);

                if (finalColor && rarityColor) {
                    finalColor = blend(finalColor, rarityColor, rarityColor.a);
                }
                
                if (finalColor) {
                    const index = (y * resolution + x) * 4;
                    data[index] = finalColor.r;
                    data[index+1] = finalColor.g;
                    data[index+2] = finalColor.b;
                    data[index+3] = 255;
                }
            }
        }
        ui.ctx.putImageData(imageData, resolution * frame, 0);
    }
}
```

## Helper Functions

These are helper functions for color manipulation.

```javascript
function getColor(value, palette) {
    for (const entry of palette) {
        if (value < entry.limit) return entry.color;
    }
    return palette[palette.length - 1].color;
}

function blend(base, tint, alpha) {
    return {
        r: Math.round(base.r * (1 - alpha) + tint.r * alpha),
        g: Math.round(base.g * (1 - alpha) + tint.g * alpha),
        b: Math.round(base.b * (1 - alpha) + tint.b * alpha)
    };
}

function hexToRgb(hex) {
    if (!hex) return null;
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? { r: parseInt(result[1], 16), g: parseInt(result[2], 16), b: parseInt(result[3], 16) } : null;
}
```
