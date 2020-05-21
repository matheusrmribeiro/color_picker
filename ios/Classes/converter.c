#include <stdio.h>
#include "converter.h"
#include <math.h>
#include <stdlib.h>

int clamp(int lower, int higher, int val){
    if(val < lower)
        return 0;
    else if(val > higher)
        return 255;
    else
        return val;
}

int getRotatedImageByteIndex(int x, int y, int rotatedImageWidth){
    return rotatedImageWidth*(y+1)-(x+1);
}

uint32_t *convertImage(uint8_t *plane0, uint8_t *plane1, uint8_t *plane2, int bytesPerRow, int bytesPerPixel, int width, int height){
     int hexFF = 255;
    int x, y, uvIndex, index;
    int yp, up, vp;
    int r, g, b;
    int rt, gt, bt;

    uint32_t *image = malloc(sizeof(uint32_t) * (width * height));

    for(x = 0; x < width; x++){
        for(y = 0; y < height; y++){
            
            uvIndex = bytesPerPixel * ((int) floor(x/2)) + bytesPerRow * ((int) floor(y/2));
            index = y*width+x;

            yp = plane0[index];
            up = plane1[uvIndex];
            vp = plane2[uvIndex];
            rt = round(yp + vp * 1436 / 1024 - 179);
            gt = round(yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91);
            bt = round(yp + up * 1814 / 1024 - 227);
            r = clamp(0, 255, rt);
            g = clamp(0, 255, gt);
            b = clamp(0, 255, bt);
            image[getRotatedImageByteIndex(y, x, height)] = (hexFF << 24) | (b << 16) | (g << 8) | r;
        }
    }
    return image;
}