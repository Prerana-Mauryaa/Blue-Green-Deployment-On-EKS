import os
from flask import Flask, render_template, request
from flask_mysqldb import MySQL

app = Flask(__name__)

# Configure MySQL from environment variables
app.config['MYSQL_HOST'] = os.environ.get('MYSQL_HOST', 'localhost')
app.config['MYSQL_USER'] = os.environ.get('MYSQL_USER', 'default_user')
app.config['MYSQL_PASSWORD'] = os.environ.get('MYSQL_PASSWORD', 'default_password')
app.config['MYSQL_DB'] = os.environ.get('MYSQL_DB', 'default_db')


# Initialize MySQL
mysql = MySQL(app) 

@app.route("/")
def home():
    return render_template('index.html')

@app.route("/index")
def newhome():
    return render_template('index.html')

@app.route("/resume")
def resume():
    return render_template('resume.html')

@app.route("/projects")
def projects():
    return render_template('projects.html')

@app.route("/contact", methods=['GET', 'POST'])
def contact():
    if request.method == 'POST':
        fullname = request.form['fullname']
        emailid = request.form['email']
        phonenumber = request.form['phonenumber']
        message = request.form['message']

        cur = mysql.connection.cursor()
        try:
            cur.execute("INSERT INTO messages (fullname, emailaddress, phonenumber, message) VALUES (%s, %s, %s, %s)",
                        (fullname, emailid, phonenumber, message))
            mysql.connection.commit()
            cur.close()
            return render_template('contact.html', success_message="Form submission successful!")
        except Exception as e:
            return render_template('contact.html', error_message="Error submitting message: " + str(e))

    return render_template('contact.html', success_message=None, error_message=None)

if __name__ == "__main__":
    app.run(debug=True)
