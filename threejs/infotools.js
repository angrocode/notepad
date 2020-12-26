

import {
    WebGLRenderer,
    OrthographicCamera,
    Scene, Color, Mesh,
    BoxBufferGeometry,
    Sprite, Vector3, REVISION,
    MeshBasicMaterial, Group,
    CanvasTexture, SpriteMaterial, Vector4
} from './three.module.js';

function InfoTools (left, top){

    this.left = left;
    this.top = top;

    const panel = document.createElement('div');
    panel.id = 'info_tools';
    panel.style.cssText = `\
        top: ${top};
        left: ${left};
        height: 80px;
        width: 200px; 
        position: absolute;
        z-index: 1000;
        display: block;
        overflow: hidden;
        border-color: #808080;
        border-style: solid;
        border-width: 1px;`;

    const canvas = document.createElement('canvas');
    canvas.id = 'info_cnvas';
    canvas.style.cssText = `\
        position: relative;
        z-index: 1000;
        display: block;
        overflow: hidden;`;

    const layer = document.createElement('div');
    layer.id = 'info_layer';
    layer.style.cssText = `\
        top: 0;
        left: 0;
        height: 100%;
        width: 100%;
        z-index: 3;
        position: absolute;
        display: grid;
        grid-template:
        "t ." auto / auto 80px`;

    const ltext = document.createElement('div');
    ltext.id = 'info_text';
    ltext.style.cssText = `\
        grid-area: t;
        z-index: 5;
        padding: 5px;
        display: block;
        overflow: hidden;
        color: #b3b3b3;
        font: small-caps bold 14px/1 sans-serif;`;

    document.body.append(panel);
    panel.append(canvas);
    panel.append(layer);
    layer.append(ltext);

    const renderer = new WebGLRenderer(
        {
            canvas: canvas,
            antialias: true,
            alpha: true,
            premultipliedAlpha: false
        }
    );
    renderer.setAnimationLoop(anime);
    renderer.setPixelRatio((window.devicePixelRatio) ? window.devicePixelRatio : 1);
    renderer.setSize(panel.clientWidth, panel.clientHeight, false);


    const camera = new OrthographicCamera();
    camera.position.set( 0, 0, 100 );

    const scene = new Scene();

    const color1  = new Color( '#ff6b81' ); // ff3653
    const color2  = new Color( '#a7ff0f' ); // 8adb00
    const color3  = new Color( '#61abff' ); // 2c8fff
    const color11 = new Color( '#d1001f' );
    const color21 = new Color( '#4a7500' );
    const color31 = new Color( '#005dc7' );

    const geometry = new BoxBufferGeometry( 20, 2.5, 2.5 );

    const xAxis = new Mesh( geometry, getAxisMaterial( color1 ) );
    const yAxis = new Mesh( geometry, getAxisMaterial( color2 ) );
    const zAxis = new Mesh( geometry, getAxisMaterial( color3 ) );
    const negXAxis = new Mesh( geometry, getAxisMaterial( color1 ) );
    const negYAxis = new Mesh( geometry, getAxisMaterial( color2 ) );
    const negZAxis = new Mesh( geometry, getAxisMaterial( color3 ) );

    yAxis.rotation.z = Math.PI / 2;
    zAxis.rotation.y = - Math.PI / 2;
    negYAxis.rotation.z = Math.PI / 2;
    negZAxis.rotation.y = - Math.PI / 2;

    xAxis.position.set(12, 0,0);
    yAxis.position.set(0, 12,0);
    zAxis.position.set(0, 0,12);
    negXAxis.position.set(-12, 0,0);
    negYAxis.position.set(0, -12,0);
    negZAxis.position.set(0, 0,-12);

    const posXAxisHelper = new Sprite( getSpriteMaterial( color1, 'X' ) );
    const posYAxisHelper = new Sprite( getSpriteMaterial( color2, 'Y' ) );
    const posZAxisHelper = new Sprite( getSpriteMaterial( color3, 'Z' ) );
    const negXAxisHelper = new Sprite( getSpriteMaterial( color1 ) );
    const negYAxisHelper = new Sprite( getSpriteMaterial( color2 ) );
    const negZAxisHelper = new Sprite( getSpriteMaterial( color3 ) );

    posXAxisHelper.position.x = 29;
    posYAxisHelper.position.y = 29;
    posZAxisHelper.position.z = 29;
    negXAxisHelper.position.x = - 29;
    negYAxisHelper.position.y = - 29;
    negZAxisHelper.position.z = - 29;

    posXAxisHelper.scale.set( 30, 30, 1 );
    posYAxisHelper.scale.set( 30, 30, 1 );
    posZAxisHelper.scale.set( 30, 30, 1 );
    negXAxisHelper.scale.set( 30, 30, 1 );
    negYAxisHelper.scale.set( 30, 30, 1 );
    negZAxisHelper.scale.set( 30, 30, 1 );

    const groupHelper = new Group();

    groupHelper.add( xAxis );
    groupHelper.add( zAxis );
    groupHelper.add( yAxis );
    groupHelper.add( negXAxis );
    groupHelper.add( negYAxis );
    groupHelper.add( negZAxis );

    groupHelper.add( posXAxisHelper );
    groupHelper.add( posYAxisHelper );
    groupHelper.add( posZAxisHelper );
    groupHelper.add( negXAxisHelper );
    groupHelper.add( negYAxisHelper );
    groupHelper.add( negZAxisHelper );

    groupHelper.position.set(0, 0, 0);

    scene.add( groupHelper );


    let startTime = Date.now();
    let couterTick = 0;
    let fps, mem;

    this.update = function (object_binding){
        couterTick ++;

        groupHelper.quaternion.copy( object_binding.quaternion ).inverse();

        if (startTime + 1000 <= Date.now()){
            fps = couterTick;
            couterTick = 0;
            startTime = Date.now();
        }
    }

    function anime(){

        mem = (performance && performance.memory) ? (performance.memory.usedJSHeapSize / (1 << 20)).toFixed(1)+ ' MB' : 'no data';

        ltext.innerText = `\
            FPS: ${fps}
            MEM: ${mem}
            REV: ${REVISION}`;

        let cw = canvas.clientWidth;
        let ch = canvas.clientHeight;

        let posX = posXAxisHelper.getWorldPosition(new Vector3());
        let posY = posYAxisHelper.getWorldPosition(new Vector3());
        let posZ = posZAxisHelper.getWorldPosition(new Vector3());

        if (posX.x < 0){
            xAxis.material.color = color11;
            negXAxis.material.color = color1;
            posXAxisHelper.material.color = color11;
            negXAxisHelper.material.color = color1;
        } else {
            xAxis.material.color = color1;
            negXAxis.material.color = color11;
            posXAxisHelper.material.color = color1;
            negXAxisHelper.material.color = color11;
        }

        if (posY.y < 0){
            yAxis.material.color = color21;
            negYAxis.material.color = color2;
            posYAxisHelper.material.color = color21;
            negYAxisHelper.material.color = color2;
        } else {
            yAxis.material.color = color2;
            negYAxis.material.color = color21;
            posYAxisHelper.material.color = color2;
            negYAxisHelper.material.color = color21;
        }

        if (posZ.z < 0){
            zAxis.material.color = color31;
            negZAxis.material.color = color3;
            posZAxisHelper.material.color = color31;
            negZAxisHelper.material.color = color3;
        } else {
            zAxis.material.color = color3;
            negZAxis.material.color = color31;
            posZAxisHelper.material.color = color3;
            negZAxisHelper.material.color = color31;
        }

        camera.left   = cw / -2;
        camera.right  = cw /  2;
        camera.top    = ch /  2;
        camera.bottom = ch / -2;
        camera.aspect = cw / ch;
        camera.near   = 0;
        camera.far    = 200;
        camera.updateProjectionMatrix();

        renderer.setViewport(55, 0, cw, ch);

        renderer.render(scene, camera);

    }

    function getAxisMaterial( color ) {

        return new MeshBasicMaterial( { color: color, toneMapped: false } );

    }

    function getSpriteMaterial( color, text = null ) {

        const canvas = document.createElement( 'canvas' );
        canvas.width = 64;
        canvas.height = 64;

        const context = canvas.getContext( '2d' );
        context.beginPath();
        context.arc( 32, 32, 16, 0, 2 * Math.PI );
        context.closePath();
        context.fillStyle = color.getStyle();
        context.fill();

        if ( text !== null ) {

            context.font = '24px Arial';
            context.textAlign = 'center';
            context.fillStyle = '#000000';
            context.fillText( text, 32, 41 );

        }

        const texture = new CanvasTexture( canvas );

        canvas.remove();

        return new SpriteMaterial( { map: texture, toneMapped: false } );

    }

}


export { InfoTools };