

import * as THREE from './three.module.js';

import { EffectComposer } from './postprocessing/EffectComposer.js';
import { RenderPass } from './postprocessing/RenderPass.js';
import { ShaderPass } from './postprocessing/ShaderPass.js';
import { CopyShader } from './postprocessing/shaders/CopyShader.js';
import { VerticalBlurShader } from './postprocessing/shaders/VerticalBlurShader.js';
import { HorizontalBlurShader } from './postprocessing/shaders/HorizontalBlurShader.js';
import { ColorifyShader } from './postprocessing/shaders/ColorifyShader.js';
import { InfoTools } from './infotools.js';
const infoCam = new InfoTools('20px', '20px');

const drawing = document.querySelector('#drawing');

let scenes = {}, cameras = {}, viewers = {};

viewers.map = document.querySelector('#map');
viewers.info = document.querySelector('#info');
viewers.tools = document.querySelector('#tools');
viewers.map.name = 'map';
viewers.info.name = 'info';
viewers.tools.name = 'tools';

scenes.map = new THREE.Scene();
scenes.info = new THREE.Scene();
scenes.tools = new THREE.Scene();
scenes.bg = new THREE.Scene();
scenes.map.name = 'map';
scenes.info.name = 'info';
scenes.tools.name = 'tools';
scenes.bg.name = 'background';

cameras.map = new THREE.OrthographicCamera();
cameras.info = new THREE.OrthographicCamera();
cameras.tools = new THREE.OrthographicCamera();
cameras.map.name = 'map';
cameras.info.name = 'info';
cameras.tools.name = 'tools';

cameras.infobg = new THREE.OrthographicCamera();
cameras.infobg.name = 'infobg';

const renderer = new THREE.WebGLRenderer(
    {
        canvas: drawing,
        antialias: true,
        alpha: true,
        premultipliedAlpha: false
    }
);
renderer.setScissorTest(true);
renderer.setAnimationLoop(anime);

{   // map

    let scene = scenes.map;

    scene.add(new THREE.HemisphereLight(0xFFFFFF, 0xFFFFFF, 5));

    const sphereGeometry = new THREE.SphereGeometry(100, 32, 32, 0, Math.PI * 2, 0, Math.PI * 2);
    // const sphereMaterial = new THREE.MeshLambertMaterial({
    //     color: 0x651085,
    //     // wireframe: true,
    //     // transparent: true
    // });
    const sphereMaterial = new THREE.MeshNormalMaterial({wireframe: true});
    const sphere = new THREE.Mesh(sphereGeometry, sphereMaterial);
    sphere.position.set(0, 0, 0);
    scene.add(sphere);

    scenes.map = scene;
}

{   // info

    let scene = scenes.info;

    scene.add(new THREE.HemisphereLight(0xFFFFFF, 0xFFFFFF, 5));

    const sphereGeometry = new THREE.SphereGeometry(75, 32, 32, 0, Math.PI * 2, 0, Math.PI * 2);
    const sphereMaterial1 = new THREE.MeshLambertMaterial({
        color: 0x333333,
        wireframe: false
    });
    const sphereMaterial2 = new THREE.MeshNormalMaterial({wireframe: true, transparent: false});
    const sphere = new THREE.Mesh(sphereGeometry, sphereMaterial2);
    sphere.position.set(0, 0, 0);
    scene.add(sphere);

    scenes.info = scene;
}

// ==================================

const scene0 = new RenderPass( scenes.bg, cameras.info );
scene0.scene.background = new THREE.Color(0xFFFFFF);
scene0.clear = false;
scene0.clearDepth = true;

const scene1 = new RenderPass( scenes.map, cameras.infobg );
scene1.clear = false;
scene1.clearDepth = true;

const scene2 = new RenderPass( scenes.info, cameras.info );
scene2.clear = false;
scene2.clearDepth = true;

const CiVblur = new ShaderPass( VerticalBlurShader );
const CiHblur = new ShaderPass( HorizontalBlurShader );
const Cicolor = new ShaderPass( ColorifyShader );

Cicolor.uniforms[ 'color' ].value = new THREE.Color(
    window.getComputedStyle(document.querySelector('#main')).backgroundColor
);

const outputPass = new ShaderPass( CopyShader );

const composerInfo = new EffectComposer(renderer);


composerInfo.addPass( scene0 );
composerInfo.addPass( scene1 );
composerInfo.addPass( Cicolor );
composerInfo.addPass( CiHblur );
composerInfo.addPass( CiVblur );
composerInfo.addPass( scene2 );
composerInfo.addPass( outputPass );

// ==================================

window.onload = setter;
window.onresize = setter;

function setter(){

    let {top: dt, left: dl, width: dw, height: dh} = drawing.getBoundingClientRect();
    let dx0 = dw / 2, dy0 = dh / 2;
    let {top: tmt, left: tml, width: mw, height: mh} = viewers.map.getBoundingClientRect();
    let mt = tmt - dt, ml = tml - dl, mx0 = ml + (mw / 2), my0 = mt + (mh / 2);
    let {top: tit, left: til, width: iw, height: ih} = viewers.info.getBoundingClientRect();
    let it = tit - dt, il = til - dl, ix0 = il + (iw / 2), iy0 = it + (ih / 2);

    renderer.setPixelRatio((window.devicePixelRatio) ? window.devicePixelRatio : 1);
    renderer.setSize(dw, dh, false);

    // map

    cameras.map.left   = mw / -2;
    cameras.map.right  = mw /  2;
    cameras.map.top    = mh /  2;
    cameras.map.bottom = mh / -2;
    cameras.map.aspect = mw / mh;
    cameras.map.near   = 0.1;
    cameras.map.far    = 99999;
    cameras.map.updateProjectionMatrix();

    // info

    cameras.info.left   = iw / -2;
    cameras.info.right  = iw /  2;
    cameras.info.top    = ih /  2;
    cameras.info.bottom = ih / -2;
    cameras.info.aspect = iw / ih;
    cameras.info.near   = 0.1;
    cameras.info.far    = 99999;
    cameras.info.updateProjectionMatrix();

    // infobg

    let cx0 = ix0 - mx0, cy0 = iy0 - my0;
    cameras.infobg.left   = cx0 - (iw / 2);
    cameras.infobg.right  = cx0 + (iw / 2);
    cameras.infobg.top    = cy0 - (ih / 2);
    cameras.infobg.bottom = cy0 + (ih / 2);
    cameras.infobg.aspect = iw / ih;
    cameras.infobg.near   = 0.1;
    cameras.infobg.far    = 99999;
    cameras.infobg.updateProjectionMatrix();


    composerInfo.setSize(iw, ih);
    composerInfo.setPixelRatio((window.devicePixelRatio) ? window.devicePixelRatio : 1);

    CiVblur.uniforms[ 'v' ].value = 1.0 / ih;
    CiHblur.uniforms[ 'h' ].value = 1.0 / iw;

}

//=======================================

function anime() {

    let clock = new THREE.Clock();
    infoCam.update(scenes.map);

    let {top: dt, left: dl, width: dw, height: dh} = drawing.getBoundingClientRect();
    let dx0 = dw / 2, dy0 = dh / 2;
    let {top: tmt, left: tml, width: mw, height: mh} = viewers.map.getBoundingClientRect();
    let mt = tmt - dt, ml = tml - dl, mx0 = ml + (mw / 2), my0 = mt + (mh / 2);
    let {top: tit, left: til, width: iw, height: ih} = viewers.info.getBoundingClientRect();
    let it = tit - dt, il = til - dl, ix0 = il + (iw / 2), iy0 = it + (ih / 2);

    // map

    renderer.setViewport(ml, (dh - my0) - (mh / 2), mw, mh);
    renderer.setScissor(ml, (dh - my0) - (mh / 2), mw, mh);

    scenes.map.rotation.y = Date.now() * 0.0005;

    renderer.render(scenes.map, cameras.map);

    // info

    renderer.setViewport(il, (dh - iy0) - (ih / 2), iw, ih);
    renderer.setScissor(il, (dh - iy0) - (ih / 2), iw, ih);

    scenes.info.rotation.y = Date.now() * 0.0005;

    //renderer.render(scenes.info, cameras.info);

    composerInfo.render(clock.getDelta());


}


