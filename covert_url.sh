#!/bin/bash
# 将相对url转为绝对url，方便其他博客直接发文
# CSDN会强制将markdown格式的图片链接转存，只能使用html img标签

dirs=(Linux CXX QT CMake Docker Golang Others)
for dir in "${dirs[@]}"; do
    (
        cd "blog/$dir" || exit 1
        echo "进入目录 blog/$dir"
        if [ ! -d ".public" ]; then
            mkdir .public || exit 1
        fi
        files=$(ls ./*.md)
        parent_dir=$(pwd | awk -F "/" '{print $NF}')
        img_url_prefix="https://gitcode.net/zcteo/github-pages/-/raw/master/blog/"
        blog_url_prefix="https://zcteo.top/blog/"
        for file in $files; do
            if [ -e ".public/$file" ]; then
                echo "正在更新 $file"
                printf '' >".public/$file"
            else
                echo "正在转换$file"
            fi

            awk '{
                    # 处理图片链接
                    if(match($0, /!\[(.*?)\]\((.*?)\)/ ,m))
                    {
                        newUrl = "'"$img_url_prefix"'" "" "'"$parent_dir/"'" "" m[2]
                        print "<img src=\"" "" newUrl "" "\" alt=\"" "" m[1] "" "\"/>"
                    }
                    # 处理站内文章链接
                    else if(match($0, /\(((.*?)\.md)\)/, m))
                    {
                        newUrl = "'"($blog_url_prefix"'" "" "'"$parent_dir/"'" "" m[2] "" ".html)"
                        sub(/\(.*?\.md\)/, newUrl, $0)
                        print $0
                    }
                    else
                    {
                        print $0
                    }
                }' "$file" >>".public/$file"

            # 加上小尾巴
            {
                printf "\n\n\n---\n"
                printf '*由于个人水平有限，文中若有不合理或不正确的地方欢迎指出改正*\n\n'
                printf '*若文中个人文章链接打不开，请在站内寻找同名文章*\n\n'
                printf '*文章可能更新不及时，请以[个人博客](https://zcteo.top/)处文章为准*\n\n'
            } >>".public/$file"

        done
        echo '-----------------------------'
    )
done
