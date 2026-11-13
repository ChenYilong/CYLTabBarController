import lottie from "lottie-miniprogram";

Component({
    properties: {
        data: Object,
        uri: String,
        loop: {
            type: Boolean,
            value: true
        },
        direction: {
            type: Number,
            value: 1
        },
        speed: {
            type: Number,
            value: 1
        }
    },
    lifetimes: {
        attached() {
            this.loadAnimation();
        },
        detached() {
            this.destroy();
        }
    },
    methods: {
        loadAnimation() {
            wx.createSelectorQuery()
                .in(this)
                .select("#canvas")
                .node(res => {
                    const canvas = res.node;
                    const context = canvas.getContext("2d");

                    // 临时解决 Lottie-miniprogram 动画模糊的问题
                    canvas.width *= 2;
                    canvas.height *= 2;

                    lottie.setup(canvas);
                    const option: LoadAnimationOption = {
                        loop: this.data.loop,
                        rendererSettings: {
                            context
                        }
                    };
                    if (this.data.data !== null) {
                        option.animationData = this.data.data;
                    }
                    if (this.data.uri !== "") {
                        option.path = this.data.uri;
                    }
                    this.ani = lottie.loadAnimation(option);
                    this.ani.setDirection(this.data.direction);
                    this.ani.setSpeed(this.data.speed);
                })
                .exec();
        },
        destroy() {
            // TODO: this.ani.destroy(); 方法报错，待官方修复
            this.ani.stop();
        }
    }
});
