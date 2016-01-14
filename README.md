# Generate github contributions report

## Research source
https://developer.github.com/v3/#authentication

https://developer.github.com/v3/users/

https://developer.github.com/v3/repos/

https://developer.github.com/v3/repos/commits/

## Generate your personal access token
https://github.com/settings/tokens

## Necessary requirements
* Ruby 2
* Git 2

## Local installation
    git clone git@github.com:prodigasistemas/github-contrib.git

    cd github-contrib

    bundle install

## Usage
    ruby contrib.rb [personal-access-token]

## Result
    [username]_github_contributions.csv

## License
[MIT License](http://www.opensource.org/licenses/MIT).
