Component({
  data: {
    feedback: false
  },

  properties: {
    label: {
      type: String,
      value: ''
    },
    detail: {
      type: String,
      value: ''
    },
    selected: {
      type: Boolean,
      value: false
    },
    active: {
      type: Boolean,
      value: false
    },
    compact: {
      type: Boolean,
      value: false
    },
    progress: {
      type: Number,
      value: 0
    },
    progressvisible: {
      type: Boolean,
      value: false
    },
    tagindex: {
      type: Number,
      value: -1
    },
    tagvalue: {
      type: String,
      value: ''
    },
    arialabel: {
      type: String,
      value: ''
    }
  },

  methods: {
    select() {
      clearTimeout(this.feedbackTimer)
      this.setData({ feedback: false }, () => {
        this.setData({ feedback: true })
      })
      this.feedbackTimer = setTimeout(() => {
        this.setData({ feedback: false })
      }, 190)
      this.triggerEvent('select', {
        index: this.data.tagindex,
        value: this.data.tagvalue
      })
    }
  },

  lifetimes: {
    detached() {
      clearTimeout(this.feedbackTimer)
    }
  }
})
