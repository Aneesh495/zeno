/**
 * Zeno Web Visualizer and Interactive Testbed.
 * Connects the compiled Haxe deterministic physics and rollback engine
 * to an interactive HTML5 canvas renderer.
 */
(function() {
    'use strict';

    // Retrieve Zeno engine class from global scope
    const ZenoClass = window.Zeno || (window.zeno && window.zeno.Zeno);
    if (!ZenoClass) {
        console.error('Failed to locate Zeno engine class in global scope.');
        return;
    }

    const canvas = document.getElementById('sim-canvas');
    const ctx = canvas.getContext('2d');

    // DOM UI elements
    const metricFrame = document.getElementById('metric-frame');
    const metricEntities = document.getElementById('metric-entities');
    const metricRollbacks = document.getElementById('metric-rollbacks');
    const metricResim = document.getElementById('metric-resim');
    const metricHash = document.getElementById('metric-hash');

    const btnPlay = document.getElementById('btn-play');
    const btnPause = document.getElementById('btn-pause');
    const btnStep = document.getElementById('btn-step');
    const btnReset = document.getElementById('btn-reset');
    const btnSpawnBall = document.getElementById('btn-spawn-ball');
    const btnSpawnBox = document.getElementById('btn-spawn-box');
    const btnInjectRollback = document.getElementById('btn-inject-rollback');

    const chkBVH = document.getElementById('chk-bvh');
    const chkVelocities = document.getElementById('chk-velocities');

    // Simulation state
    let engine = null;
    let isRunning = true;
    let animationId = null;

    // Viewport configuration (meters to pixels)
    const SCALE = 24.0;
    let offsetX = canvas.width / 2;
    let offsetY = canvas.height * 0.72;

    function resizeCanvas() {
        const rect = canvas.getBoundingClientRect();
        canvas.width = rect.width * window.devicePixelRatio;
        canvas.height = rect.height * window.devicePixelRatio;
        offsetX = canvas.width / 2;
        offsetY = canvas.height * 0.72;
    }

    window.addEventListener('resize', resizeCanvas);
    resizeCanvas();

    function worldToScreen(wx, wy) {
        return {
            x: offsetX + wx * SCALE,
            y: offsetY - wy * SCALE
        };
    }

    function screenToWorld(sx, sy) {
        return {
            x: (sx - offsetX) / SCALE,
            y: (offsetY - sy) / SCALE
        };
    }

    function initSimulation() {
        engine = new ZenoClass(1337);

        // Ground platform
        engine.spawnBox(24.0, 0.8, 0.0, -2.0, false);

        // Left and right containment walls
        engine.spawnBox(0.8, 12.0, -22.0, 8.0, false);
        engine.spawnBox(0.8, 12.0, 22.0, 8.0, false);

        // Angled funnels
        engine.spawnBox(10.0, 0.5, -12.0, 16.0, false);
        engine.spawnBox(10.0, 0.5, 12.0, 12.0, false);

        // Initial stack of dynamic boxes and spheres
        for (let row = 0; row < 5; row++) {
            for (let col = -3; col <= 3; col++) {
                const x = col * 2.2 + (row % 2 === 1 ? 1.0 : 0.0);
                const y = 1.0 + row * 2.2;
                if ((row + col) % 2 === 0) {
                    engine.spawnBox(0.8, 0.8, x, y, true);
                } else {
                    engine.spawnCircle(0.8, x, y, true);
                }
            }
        }
    }

    function stepSimulation() {
        if (!engine) return;

        // Player 0 submits input
        engine.submitInput(0, 0);
        engine.step();
    }

    function formatHex(num) {
        return '0x' + (num >>> 0).toString(16).toUpperCase().padStart(8, '0');
    }

    function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        if (!engine) return;
        const state = engine.getStateForRenderer();

        // Update metrics
        metricFrame.textContent = state.frame;
        metricEntities.textContent = state.entityCount;
        metricRollbacks.textContent = state.rollbacks;
        metricResim.textContent = state.resimulated;
        metricHash.textContent = formatHex(state.checksum);

        // Draw grid
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.04)';
        ctx.lineWidth = 1;
        const gridStep = SCALE * 2;
        for (let x = offsetX % gridStep; x < canvas.width; x += gridStep) {
            ctx.beginPath();
            ctx.moveTo(x, 0);
            ctx.lineTo(x, canvas.height);
            ctx.stroke();
        }
        for (let y = offsetY % gridStep; y < canvas.height; y += gridStep) {
            ctx.beginPath();
            ctx.moveTo(0, y);
            ctx.lineTo(canvas.width, y);
            ctx.stroke();
        }

        const showBVH = chkBVH.checked;
        const showVel = chkVelocities.checked;

        // Draw broadphase BVH AABBs
        if (showBVH) {
            ctx.lineWidth = 1;
            ctx.strokeStyle = 'rgba(46, 160, 67, 0.35)';
            ctx.fillStyle = 'rgba(46, 160, 67, 0.03)';
            for (let i = 0; i < state.bodies.length; i++) {
                const b = state.bodies[i];
                const pMin = worldToScreen(b.minX, b.maxY);
                const pMax = worldToScreen(b.maxX, b.minY);
                const w = pMax.x - pMin.x;
                const h = pMax.y - pMin.y;
                ctx.fillRect(pMin.x, pMin.y, w, h);
                ctx.strokeRect(pMin.x, pMin.y, w, h);
            }
        }

        // Draw rigid bodies
        for (let i = 0; i < state.bodies.length; i++) {
            const b = state.bodies[i];
            const spos = worldToScreen(b.x, b.y);

            ctx.save();
            ctx.translate(spos.x, spos.y);
            ctx.rotate(-b.angle);

            if (b.type === 'static') {
                ctx.fillStyle = '#21262d';
                ctx.strokeStyle = '#30363d';
                ctx.lineWidth = 2;
            } else if (!b.isAwake) {
                ctx.fillStyle = '#161b22';
                ctx.strokeStyle = '#8b949e';
                ctx.lineWidth = 1.5;
            } else {
                ctx.fillStyle = '#1f6feb';
                ctx.strokeStyle = '#58a6ff';
                ctx.lineWidth = 2;
            }

            if (b.shapeType === 'circle') {
                const rad = b.radius * SCALE;
                ctx.beginPath();
                ctx.arc(0, 0, rad, 0, Math.PI * 2);
                ctx.fill();
                ctx.stroke();

                // Orientation line
                ctx.strokeStyle = '#ffffff';
                ctx.lineWidth = 2;
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(rad, 0);
                ctx.stroke();
            } else if (b.shapeType === 'box') {
                const hw = b.halfWidth * SCALE;
                const hh = b.halfHeight * SCALE;
                ctx.fillRect(-hw, -hh, hw * 2, hh * 2);
                ctx.strokeRect(-hw, -hh, hw * 2, hh * 2);
            }

            ctx.restore();

            // Velocity vectors
            if (showVel && b.type === 'dynamic') {
                ctx.strokeStyle = '#f0883e';
                ctx.lineWidth = 1.5;
                ctx.beginPath();
                ctx.moveTo(spos.x, spos.y);
                ctx.lineTo(spos.x + b.vx * 4, spos.y - b.vy * 4);
                ctx.stroke();
            }
        }

        // Draw contact points and normals
        if (state.contacts && state.contacts.length > 0) {
            ctx.fillStyle = '#ff7b72';
            ctx.strokeStyle = '#ffa657';
            ctx.lineWidth = 1.5;
            for (let i = 0; i < state.contacts.length; i++) {
                const c = state.contacts[i];
                const cp = worldToScreen(c.px, c.py);
                ctx.beginPath();
                ctx.arc(cp.x, cp.y, 3, 0, Math.PI * 2);
                ctx.fill();

                ctx.beginPath();
                ctx.moveTo(cp.x, cp.y);
                ctx.lineTo(cp.x + c.nx * 10, cp.y - c.ny * 10);
                ctx.stroke();
            }
        }
    }

    let lastTime = 0;
    const frameDuration = 1000 / 60;
    let accumulator = 0;

    function loop(timestamp) {
        if (!lastTime) lastTime = timestamp;
        const delta = timestamp - lastTime;
        lastTime = timestamp;

        if (isRunning) {
            accumulator += Math.min(delta, 100);
            while (accumulator >= frameDuration) {
                stepSimulation();
                accumulator -= frameDuration;
            }
        }

        render();
        animationId = requestAnimationFrame(loop);
    }

    // Event handlers
    btnPlay.addEventListener('click', function() {
        isRunning = true;
    });

    btnPause.addEventListener('click', function() {
        isRunning = false;
    });

    btnStep.addEventListener('click', function() {
        isRunning = false;
        stepSimulation();
        render();
    });

    btnReset.addEventListener('click', function() {
        initSimulation();
        render();
    });

    btnSpawnBall.addEventListener('click', function() {
        if (!engine) return;
        const rx = (Math.random() - 0.5) * 16.0;
        engine.spawnCircle(0.8, rx, 20.0, true);
    });

    btnSpawnBox.addEventListener('click', function() {
        if (!engine) return;
        const rx = (Math.random() - 0.5) * 16.0;
        engine.spawnBox(0.8, 0.8, rx, 20.0, true);
    });

    btnInjectRollback.addEventListener('click', function() {
        if (!engine) return;
        // Inject remote input 10 frames in the past to force speculative resimulation
        engine.injectRollback(10, 1, 0x01);
        console.log('[Zeno Visualizer] Injected remote packet 10 frames back. Rollbacks triggered: ' + engine.rollback.getTotalRollbacks());
    });

    // Click on canvas to spawn a sphere at mouse position
    canvas.addEventListener('click', function(evt) {
        if (!engine) return;
        const rect = canvas.getBoundingClientRect();
        const sx = (evt.clientX - rect.left) * (canvas.width / rect.width);
        const sy = (evt.clientY - rect.top) * (canvas.height / rect.height);
        const worldCoords = screenToWorld(sx, sy);
        engine.spawnCircle(0.75, worldCoords.x, worldCoords.y, true);
    });

    // Start simulation
    initSimulation();
    animationId = requestAnimationFrame(loop);
})();
