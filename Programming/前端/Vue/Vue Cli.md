## 安装
首先需要安装 node 和 npm，然后用npm安装，注意不要安装 vue-cli，那个是比较老的版本。安装的时候可以使用 -g参数，这样安装到全局路径，而不是当前路径。创建项目的时候，可以指定vue 2还是vue 3，建议先使用vue 2，vue 3相对来说复杂一些
```
npm install @vue/cli -g
# 或者 npm i @vue/cli -g，用i是简写install

vue create my-vue-project
# vue ui 命令也能通过网页创建项目，用的比较少
```

在 vue 项目的根路径，有一个 package.json，里面script部分，有项目的一些脚本，我们可使用 npm run 来启动这些脚本，比如 npm run serve就开始执行vue-cli-service serve命令启动我们的服务，这个适合开发的时候使用。npm run build就开始将应用打包成静态资源，之后我们可以用一些服务器来host这些静态资源，比如我们可以 npm install serve -g，之后用 serve dist/ 就可以启动网站host dist/路径资源.
```
  "scripts": {
    "serve": "vue-cli-service serve",
    "build": "vue-cli-service build",
    "lint": "vue-cli-service lint"
  },
```

