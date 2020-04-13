<!-- gitalk.swig -->
<link href="https://cdn.bootcss.com/gitalk/1.4.0/gitalk.min.css" rel="stylesheet" />
<script src="https://cdn.bootcss.com/gitalk/1.4.0/gitalk.min.js"></script>
<script src="https://cdn.bootcss.com/blueimp-md5/2.10.0/js/md5.min.js"></script>
<script type="text/javascript">
  var gitalk = new Gitalk({
    clientID: '{{ theme.gitalk.ClientID }}',
    clientSecret: '{{ theme.gitalk.ClientSecret }}',
    repo: '{{ theme.gitalk.repo }}',
    owner: '{{ theme.gitalk.owner }}',
    admin: ['{{ theme.gitalk.adminUser }}'],
    id: md5(location.pathname),   // ISSUE：location.href 限制50个字符 (应该是Issue 内容存数据库的标识， 具体在页面上无感)
    labels: '{{ theme.gitalk.labels }}'.split(',').filter(l => l),  // 需要的 labels需要一个数组，否则会报错
    perPage: {{ theme.gitalk.perPage }},
    pagerDirection: '{{ theme.gitalk.pagerDirection }}',
    createIssueManually: {{ theme.gitalk.createIssueManually }},
    distractionFreeMode: {{ theme.gitalk.distractionFreeMode }}
  })
  gitalk.render('gitalk-container')
</script>
