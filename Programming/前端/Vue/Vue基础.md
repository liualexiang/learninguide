# Vue 基础

基础语法

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>VueProject</title>
</head>
<body>

<div id="app">
    {{message}}
    <span v-bind:title="message">鼠标悬停绑定</span>

    <h1 v-if="ok">OK</h1>
    <h1 v-else>NOK</h1>

    <h1 v-if="type==='A'">A</h1>
    <h1 v-else-if="type==='B'">B</h1>

    <li v-for="(item, index) in items">{{item.message}}--{{index}}</li>

    <button v-on:click="sayHi">click me</button>
</div>



<script src="https://unpkg.com/vue@3/dist/vue.global.js"></script>
<script>
    const app = Vue.createApp(
        {
            data() {
                return {
                    message: "yyyy",
                    ok: false,
                    type: "B",
                    items: [
                        {message: "msg1"},
                        {message: "msg2"},
                        {message: "msg3"}
                    ]
                }
            },
            methods: {
                sayHi(event)  {
                    alert(this.message)
                }
            }
        }
    )
    app.mount("#app")

    console.log(app.message)
</script>

</body>
</html>
```

